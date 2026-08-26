const [mode, portText, browserName = 'browser'] = process.argv.slice(2)
const port = Number(portText)

if (!['happy', 'failure', 'recovery'].includes(mode) || !Number.isInteger(port)) {
  throw new Error('Usage: node verify-live-browser.mjs <happy|failure|recovery> <cdp-port> <browser-name>')
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
    const limit = Date.now() + 10000;
    while (document.readyState !== 'complete') {
      if (Date.now() > limit) throw new Error('Navigation timeout');
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    return location.pathname;
  })()`)
}

const browserHelpers = `
  const waitFor = async (predicate, label, timeout = 15000) => {
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
`

async function viewportEvidence(width, height) {
  await command('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width <= 390 })
  return evaluate(`({ width: document.documentElement.clientWidth, scrollWidth: document.documentElement.scrollWidth })`)
}

try {
  await command('Page.enable')
  await command('Runtime.enable')

  if (mode === 'happy') {
    await navigate('/')
    const home = await evaluate(`(async () => {
      ${browserHelpers}
      await waitFor(() => document.querySelector('[data-current-hours-source="reservation-context"]'), 'live current hours');
      const hours = [...document.querySelectorAll('[data-current-hours-source="reservation-context"] p')].map((entry) => entry.textContent.trim());
      if (hours.length !== 8) throw new Error('Expected timezone plus seven current-hours rows');

      const email = 'prompt24-browser-${browserName}-' + Date.now() + '@example.test';
      setValue(document.querySelector('#newsletter_first_name'), 'Browser');
      setValue(document.querySelector('#newsletter_last_name'), 'Verifier');
      setValue(document.querySelector('#newsletter_email'), email);
      setValue(document.querySelector('#newsletter_confirmation_email'), email);
      await waitFor(() => document.querySelector('#newsletter-lookup-status').textContent.includes('No existing'), 'live newsletter not_found');
      document.querySelector('#newsletter_subscribed').click();
      button('Save newsletter preference').click();
      await waitFor(() => document.body.innerText.includes('Newsletter preference saved'), 'live newsletter saved');
      setValue(document.querySelector('#newsletter_first_name'), 'Different');
      await waitFor(() => document.querySelector('#newsletter-lookup-status').textContent.includes('do not match'), 'live newsletter identity conflict');
      return { hours: hours.slice(1), newsletterSaved: true, conflict: true };
    })()`)

    await navigate('/reservations')
    const reservation = await evaluate(`(async () => {
      ${browserHelpers}
      await waitFor(() => document.querySelector('#local_date') && document.body.innerText.includes('Reservation options are ready'), 'live reservation context');
      const dateInput = document.querySelector('#local_date');
      const minimum = new Date(dateInput.min + 'T12:00:00Z');
      minimum.setUTCDate(minimum.getUTCDate() + 2);
      const localDate = minimum.toISOString().slice(0, 10);
      setValue(dateInput, localDate);
      setValue(document.querySelector('#party_size'), '4');
      button('Check availability').click();
      await waitFor(() => document.querySelector('input[name="reservation_slot"]:not(:disabled)'), 'live available slot');
      document.querySelector('input[name="reservation_slot"]:not(:disabled)').click();

      const email = 'prompt24-reservation-${browserName}-' + Date.now() + '@example.test';
      setValue(document.querySelector('#first_name'), 'Browser');
      setValue(document.querySelector('#last_name'), 'Reservation');
      setValue(document.querySelector('#email'), email);
      setValue(document.querySelector('#confirmation_email'), email);
      setValue(document.querySelector('#phone'), '+1 (202) 555-0199');
      await waitFor(() => [...document.querySelectorAll('[role="status"]')].some((node) => node.textContent.includes('No existing newsletter')), 'reservation newsletter lookup');
      document.querySelector('#reservation_newsletter').click();
      button('Reserve table').click();
      await waitFor(() => document.querySelector('#confirmation-heading'), 'live reservation confirmation', 20000);
      const text = document.querySelector('.confirmation-view').innerText;
      if (text.includes(email)) throw new Error('Confirmation leaked submitted email');
      if (!text.includes('Reference') || !text.includes('Assigned table') || !text.includes('Canonical UTC')) throw new Error('Confirmation omitted public server facts');
      return { confirmation: true, emailWithheld: true, textLength: text.length };
    })()`)

    const mobile = await viewportEvidence(390, 844)
    const desktop = await viewportEvidence(1280, 900)
    if (mobile.scrollWidth !== mobile.width || desktop.scrollWidth !== desktop.width) throw new Error('Live content introduced horizontal overflow.')
    console.log(JSON.stringify({ browser: browserName, mode, home, reservation, mobile, desktop }))
  }

  if (mode === 'failure') {
    await navigate('/')
    const failure = await evaluate(`(async () => {
      ${browserHelpers}
      await waitFor(() => document.body.innerText.includes('Current hours are unavailable'), 'read transport failure');
      const email = 'prompt24-ambiguity-${browserName}-' + Date.now() + '@example.test';
      setValue(document.querySelector('#newsletter_first_name'), 'Transport');
      setValue(document.querySelector('#newsletter_last_name'), 'Ambiguity');
      setValue(document.querySelector('#newsletter_email'), email);
      setValue(document.querySelector('#newsletter_confirmation_email'), email);
      await new Promise((resolve) => setTimeout(resolve, 700));
      if (!document.querySelector('#newsletter_subscribed').checked) document.querySelector('#newsletter_subscribed').click();
      button('Save newsletter preference').click();
      await waitFor(() => document.body.innerText.includes('Newsletter result not confirmed'), 'mutation outcome unknown');
      if (!button('Resend the same preference')) throw new Error('Exact mutation recovery action is absent');
      return { readFailure: true, mutationUnknown: true, recoveryLocked: document.querySelector('#newsletter_first_name').matches(':disabled') };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, failure }))
  }

  if (mode === 'recovery') {
    const recovery = await evaluate(`(async () => {
      ${browserHelpers}
      const resend = button('Resend the same preference');
      if (!resend) throw new Error('Preserved mutation recovery action is absent');
      resend.click();
      await waitFor(() => document.body.innerText.includes('Newsletter preference saved'), 'identical mutation recovery');
      const retryHours = button('Try again');
      if (!retryHours) throw new Error('Read retry action is absent');
      retryHours.click();
      await waitFor(() => document.querySelector('[data-current-hours-source="reservation-context"]'), 'read recovery');
      return { mutationRecovered: true, readRecovered: true };
    })()`)
    console.log(JSON.stringify({ browser: browserName, mode, recovery }))
  }
} finally {
  socket.close()
}
