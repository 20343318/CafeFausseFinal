const [mode, portText, browserName = 'browser', runId, ...args] = process.argv.slice(2)
const port = Number(portText)

const modes = new Set(['newsletter', 'context', 'reservation-success', 'reservation-unknown', 'reservation-recover', 'fully-booked'])
if (!modes.has(mode) || !Number.isInteger(port) || !runId) {
  throw new Error('Usage: node verify-full-integration-browser.mjs <mode> <cdp-port> <browser-name> <run-id> [mode arguments]')
}

const targets = await fetch(`http://127.0.0.1:${port}/json`).then((response) => response.json())
const target = targets.find((candidate) => candidate.type === 'page')
if (!target?.webSocketDebuggerUrl) throw new Error('No browser page target is available.')

const socket = new WebSocket(target.webSocketDebuggerUrl)
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, { once: true })
  socket.addEventListener('error', reject, { once: true })
})

let nextId = 0
const pending = new Map()
socket.addEventListener('message', (event) => {
  const message = JSON.parse(event.data)
  if (!message.id || !pending.has(message.id)) return
  const { resolve, reject } = pending.get(message.id)
  pending.delete(message.id)
  if (message.error) reject(new Error(message.error.message))
  else resolve(message.result)
})

function command(method, params = {}) {
  const id = ++nextId
  socket.send(JSON.stringify({ id, method, params }))
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }))
}

async function evaluate(expression) {
  const result = await command('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
    userGesture: true,
  })
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || 'Browser evaluation failed.')
  return result.result.value
}

async function navigate(path) {
  await command('Page.navigate', { url: `http://127.0.0.1:5173${path}` })
  await evaluate(`(async () => {
    const limit = Date.now() + 15000;
    while (document.readyState !== 'complete') {
      if (Date.now() > limit) throw new Error('Navigation timeout');
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    return location.pathname;
  })()`)
}

const helpers = `
  const waitFor = async (predicate, label, timeout = 20000) => {
    const limit = Date.now() + timeout;
    while (!predicate()) {
      if (Date.now() > limit) throw new Error('Timed out waiting for ' + label);
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
  };
  const setValue = (element, value) => {
    const setter = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(element), 'value').set;
    setter.call(element, value);
    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
  };
  const button = (text) => [...document.querySelectorAll('button')].find((candidate) => candidate.textContent.trim() === text);
  const definition = (term) => {
    const dt = [...document.querySelectorAll('dt')].find((candidate) => candidate.textContent.trim() === term);
    return dt?.nextElementSibling?.textContent.trim();
  };
`

async function loadReservationSchedule(localDate, partySize) {
  await navigate('/reservations')
  return evaluate(`(async () => {
    ${helpers}
    await waitFor(() => document.querySelector('#local_date') && document.body.innerText.includes('Reservation options are ready'), 'reservation context');
    setValue(document.querySelector('#local_date'), ${JSON.stringify(localDate)});
    setValue(document.querySelector('#party_size'), ${JSON.stringify(String(partySize))});
    button('Check availability').click();
    await waitFor(() => document.querySelector('.slot-grid') || document.body.innerText.includes('No reservation times are offered'), 'reservation schedule');
    return true;
  })()`)
}

try {
  await command('Page.enable')
  await command('Runtime.enable')

  if (mode === 'newsletter') {
    await navigate('/')
    const result = await evaluate(`(async () => {
      ${helpers}
      await waitFor(() => document.querySelector('[data-current-hours-source="reservation-context"]'), 'live current hours');
      const email = ${JSON.stringify(`prompt25-newsletter-${runId}@example.test`)};
      const otherEmail = ${JSON.stringify(`prompt25-invalid-${runId}@example.test`)};
      const originalFetch = window.fetch.bind(window);
      let preferenceRequests = 0;
      window.fetch = (...fetchArgs) => {
        const url = String(fetchArgs[0]);
        const method = String(fetchArgs[1]?.method || 'GET').toUpperCase();
        if (url.endsWith('/api/v1/newsletter-preferences') && method === 'POST') preferenceRequests += 1;
        return originalFetch(...fetchArgs);
      };

      setValue(document.querySelector('#newsletter_first_name'), 'Prompt');
      setValue(document.querySelector('#newsletter_middle_initial'), 'M.');
      setValue(document.querySelector('#newsletter_last_name'), 'Twentyfive');
      setValue(document.querySelector('#newsletter_email'), email);
      setValue(document.querySelector('#newsletter_confirmation_email'), email);
      await waitFor(() => document.querySelector('#newsletter-lookup-status').textContent.includes('No existing'), 'newsletter not-found');
      document.querySelector('#newsletter_subscribed').click();
      document.querySelector('form[aria-label="Newsletter preferences"]').requestSubmit();
      await waitFor(() => preferenceRequests === 1 && document.querySelector('form[aria-label="Newsletter preferences"]').getAttribute('aria-busy') === 'false' && document.body.innerText.includes('Newsletter preference saved'), 'newsletter creation');

      const firstSuccess = [...document.querySelectorAll('.status-panel')].find((node) => node.textContent.includes('Newsletter preference saved'));
      document.querySelector('form[aria-label="Newsletter preferences"]').requestSubmit();
      await waitFor(() => firstSuccess && !firstSuccess.isConnected, 'duplicate newsletter dispatch');
      await waitFor(() => preferenceRequests === 2 && document.querySelector('form[aria-label="Newsletter preferences"]').getAttribute('aria-busy') === 'false' && document.body.innerText.includes('Newsletter preference saved'), 'duplicate newsletter save');

      setValue(document.querySelector('#newsletter_middle_initial'), 'N');
      await waitFor(() => document.querySelector('#newsletter-lookup-status').textContent.includes('do not match'), 'middle-initial lookup conflict');
      document.querySelector('form[aria-label="Newsletter preferences"]').requestSubmit();
      await waitFor(() => preferenceRequests === 3 && document.querySelector('form[aria-label="Newsletter preferences"]').getAttribute('aria-busy') === 'false' && document.body.innerText.includes('middle initial conflicts'), 'middle-initial mutation conflict');

      setValue(document.querySelector('#newsletter_middle_initial'), 'M');
      setValue(document.querySelector('#newsletter_first_name'), 'Different');
      await waitFor(() => document.querySelector('#newsletter-lookup-status').textContent.includes('do not match'), 'identity lookup conflict');
      document.querySelector('form[aria-label="Newsletter preferences"]').requestSubmit();
      await waitFor(() => preferenceRequests === 4 && document.querySelector('form[aria-label="Newsletter preferences"]').getAttribute('aria-busy') === 'false' && document.body.innerText.includes('identity details do not match'), 'identity mutation conflict');

      setValue(document.querySelector('#newsletter_first_name'), 'Prompt');
      setValue(document.querySelector('#newsletter_email'), email);
      setValue(document.querySelector('#newsletter_confirmation_email'), otherEmail);
      document.querySelector('form[aria-label="Newsletter preferences"]').requestSubmit();
      await waitFor(() => document.body.innerText.includes('Email addresses must match'), 'client newsletter validation');
      await new Promise((resolve) => setTimeout(resolve, 150));
      if (preferenceRequests !== 4) throw new Error('Client-invalid newsletter data reached OP-04.');

      return {
        email,
        preferenceRequests,
        created: true,
        duplicateIdempotent: true,
        middleConflict: true,
        identityConflict: true,
        invalidClientBlocked: true,
      };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }

  if (mode === 'context') {
    const [localDate, partySizeText = '4'] = args
    if (!localDate) throw new Error('context mode requires a local date.')
    await loadReservationSchedule(localDate, Number(partySizeText))
    const result = await evaluate(`(() => {
      ${helpers}
      return {
        minimumLocalDate: document.querySelector('#local_date').min,
        maximumLocalDate: document.querySelector('#local_date').max,
        maximumPartySize: Number(document.querySelector('#party_size').max),
        policy: [...document.querySelectorAll('.context-facts dd')].map((node) => node.textContent.trim()),
        hours: [...document.querySelectorAll('.context-summary details p')].map((node) => node.textContent.trim()),
        slots: [...document.querySelectorAll('input[name="reservation_slot"]')].map((input) => ({
          startsAtLocal: input.value,
          disabled: input.disabled,
          label: input.closest('label').innerText.trim(),
        })),
      };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }

  if (mode === 'reservation-success') {
    const [localDate, partySizeText = '6'] = args
    if (!localDate) throw new Error('reservation-success mode requires a local date.')
    await loadReservationSchedule(localDate, Number(partySizeText))
    const result = await evaluate(`(async () => {
      ${helpers}
      const slot = document.querySelector('input[name="reservation_slot"]:not(:disabled)');
      if (!slot) throw new Error('No available slot exists for the UI reservation.');
      slot.click();
      const selectedStart = slot.value;
      const email = ${JSON.stringify(`prompt25-reservation-${runId}@example.test`)};
      setValue(document.querySelector('#first_name'), 'Prompt');
      setValue(document.querySelector('#middle_initial'), 'R.');
      setValue(document.querySelector('#last_name'), 'Twentyfive');
      setValue(document.querySelector('#email'), email);
      setValue(document.querySelector('#confirmation_email'), email);
      setValue(document.querySelector('#phone'), '+1 (202) 555-0125');
      await waitFor(() => [...document.querySelectorAll('[role="status"]')].some((node) => node.textContent.includes('No existing newsletter')), 'reservation newsletter lookup');
      document.querySelector('#reservation_newsletter').click();
      button('Reserve table').click();
      await waitFor(() => document.querySelector('#confirmation-heading'), 'reservation confirmation', 25000);
      const assignedTables = definition('Assigned tables') || definition('Assigned table');
      return {
        email,
        selectedStart,
        customerName: definition('Name'),
        reservationReference: definition('Reference'),
        localInterval: definition('Restaurant-local interval'),
        startsAt: definition('Canonical UTC start'),
        endsAt: definition('Canonical UTC end'),
        partySize: Number(definition('Party size')),
        assignedTables: assignedTables.split(',').map((value) => Number(value.trim())),
        newsletter: definition('Newsletter'),
        confirmationVisible: true,
      };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }

  if (mode === 'reservation-unknown') {
    const [localDate, partySizeText = '4'] = args
    if (!localDate) throw new Error('reservation-unknown mode requires a local date.')
    await loadReservationSchedule(localDate, Number(partySizeText))
    const result = await evaluate(`(async () => {
      ${helpers}
      const slot = document.querySelector('input[name="reservation_slot"]:not(:disabled)');
      if (!slot) throw new Error('No available slot exists for retry verification.');
      slot.click();
      const selectedStart = slot.value;
      const email = ${JSON.stringify(`prompt25-retry-${runId}@example.test`)};
      setValue(document.querySelector('#first_name'), 'Prompt');
      setValue(document.querySelector('#middle_initial'), 'T.');
      setValue(document.querySelector('#last_name'), 'Twentyfive');
      setValue(document.querySelector('#email'), email);
      setValue(document.querySelector('#confirmation_email'), email);
      await waitFor(() => [...document.querySelectorAll('[role="status"]')].some((node) => node.textContent.includes('No existing newsletter')), 'retry newsletter lookup');
      document.querySelector('#reservation_newsletter').click();

      const originalFetch = window.fetch.bind(window);
       window.__prompt25Op05Attempts = 0;
       window.__prompt25CommittedResponse = null;
       window.__prompt25RetryResponse = null;
       window.__prompt25SubmittedBody = null;
       window.__prompt25SubmittedBodyText = null;
       window.__prompt25RetryBodyText = null;
       window.fetch = async (...fetchArgs) => {
         const url = String(fetchArgs[0]);
         const options = fetchArgs[1] || {};
         if (url.endsWith('/api/v1/reservations') && String(options.method || 'GET').toUpperCase() === 'POST') {
           window.__prompt25Op05Attempts += 1;
           const response = await originalFetch(...fetchArgs);
           if (window.__prompt25Op05Attempts === 1) {
             window.__prompt25SubmittedBody = JSON.parse(options.body);
             window.__prompt25SubmittedBodyText = options.body;
             window.__prompt25CommittedResponse = { status: response.status, body: await response.clone().json() };
             throw new TypeError('Controlled post-response transport loss');
           }
           if (window.__prompt25Op05Attempts === 2) {
             window.__prompt25RetryBodyText = options.body;
             window.__prompt25RetryResponse = { status: response.status, body: await response.clone().json() };
           }
           return response;
         }
         return originalFetch(...fetchArgs);
       };

      button('Reserve table').click();
      await waitFor(() => document.body.innerText.includes('Reservation result not confirmed') && button('Retry the same reservation'), 'reservation unknown-outcome state', 25000);
      return {
        email,
        selectedStart,
        committedResponse: window.__prompt25CommittedResponse,
        submittedBody: window.__prompt25SubmittedBody,
        submittedBodyText: window.__prompt25SubmittedBodyText,
        outcomeUnknown: true,
        recoveryLocked: document.querySelector('#first_name').matches(':disabled'),
      };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }

  if (mode === 'reservation-recover') {
    const result = await evaluate(`(async () => {
      ${helpers}
      const retry = button('Retry the same reservation');
      if (!retry) throw new Error('The exact reservation retry action is absent.');
      retry.click();
      await waitFor(() => document.querySelector('#confirmation-heading'), 'exact-retry confirmation', 25000);
      const assignedTables = definition('Assigned tables') || definition('Assigned table');
      return {
        recovered: document.body.innerText.includes('Your existing reservation was recovered'),
        reservationReference: definition('Reference'),
        assignedTables: assignedTables.split(',').map((value) => Number(value.trim())),
        newsletter: definition('Newsletter'),
        attempts: window.__prompt25Op05Attempts,
        retryBodyText: window.__prompt25RetryBodyText,
        retryResponse: window.__prompt25RetryResponse,
      };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }

  if (mode === 'fully-booked') {
    const [localDate, partySizeText = '120'] = args
    if (!localDate) throw new Error('fully-booked mode requires a local date.')
    await loadReservationSchedule(localDate, Number(partySizeText))
    const result = await evaluate(`(() => {
      const slots = [...document.querySelectorAll('input[name="reservation_slot"]')];
      if (!slots.length) throw new Error('The fully booked schedule contained no legitimate slots.');
      if (!document.body.innerText.includes('All offered times are currently unavailable')) throw new Error('The fully booked user-facing status is absent.');
      if (slots.some((slot) => !slot.disabled)) throw new Error('A fully booked slot remained selectable.');
      return { slotCount: slots.length, disabledCount: slots.filter((slot) => slot.disabled).length, fullyBookedMessage: true };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, result }))
  }
} finally {
  socket.close()
}
