import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { performance } from 'node:perf_hooks'

const [portText, outputPath, runId] = process.argv.slice(2)
const port = Number(portText)
if (!Number.isInteger(port) || !outputPath || !runId) {
  throw new Error('Usage: node verify-nfr-performance-browser.mjs <cdp-port> <output-json> <run-id>')
}

const baseUrl = 'http://127.0.0.1:5173'
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
const eventWaiters = new Map()
socket.addEventListener('message', (event) => {
  const message = JSON.parse(event.data)
  if (message.id && pending.has(message.id)) {
    const { resolve, reject } = pending.get(message.id)
    pending.delete(message.id)
    if (message.error) reject(new Error(message.error.message))
    else resolve(message.result)
    return
  }
  const waiters = eventWaiters.get(message.method)
  if (waiters?.length) waiters.shift()(message.params)
})

function command(method, params = {}) {
  const id = ++nextId
  socket.send(JSON.stringify({ id, method, params }))
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }))
}

function waitForEvent(method, timeout = 20000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${method}.`)), timeout)
    const wrapped = (params) => {
      clearTimeout(timer)
      resolve(params)
    }
    const waiters = eventWaiters.get(method) || []
    waiters.push(wrapped)
    eventWaiters.set(method, waiters)
  })
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

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))
const round = (value) => Number(value.toFixed(3))

function cpuSnapshot() {
  return os.cpus().reduce((total, cpu) => {
    for (const [name, ticks] of Object.entries(cpu.times)) total[name] = (total[name] || 0) + ticks
    return total
  }, {})
}

function cpuPercent(before, after) {
  const totalBefore = Object.values(before).reduce((sum, value) => sum + value, 0)
  const totalAfter = Object.values(after).reduce((sum, value) => sum + value, 0)
  const totalDelta = totalAfter - totalBefore
  const idleDelta = after.idle - before.idle
  return totalDelta > 0 ? round(((totalDelta - idleDelta) / totalDelta) * 100) : 0
}

function percentileNearestRank(values, percentile) {
  const sorted = [...values].sort((a, b) => a - b)
  return sorted[Math.max(0, Math.ceil(percentile * sorted.length) - 1)]
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b)
  const middle = Math.floor(sorted.length / 2)
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
}

function summary(samples, includeP95 = false) {
  const values = samples.map((sample) => sample.elapsed_ms)
  const result = {
    minimum_ms: round(Math.min(...values)),
    median_ms: round(median(values)),
    maximum_ms: round(Math.max(...values)),
  }
  if (includeP95) result.p95_nearest_rank_ms = round(percentileNearestRank(values, 0.95))
  return result
}

async function waitForPageReady(path, navigationToken, timeout = 20000) {
  const readiness = {
    '/': "document.querySelector('h1')?.textContent.trim() === 'Café Fausse' && document.querySelector('[data-current-hours-source=\"reservation-context\"]')",
    '/menu': "document.querySelector('h1')?.textContent.trim() === 'Menu' && document.querySelectorAll('.menu-grid .menu-section').length === 4",
    '/reservations': "document.querySelector('h1')?.textContent.trim() === 'Reservations' && document.querySelector('#local_date') && document.body.innerText.includes('Reservation options are ready')",
    '/about': "document.querySelector('h1')?.textContent.trim() === 'About Us' && document.querySelector('#about-story-heading') && document.querySelector('#founders-heading')",
    '/gallery': "document.querySelector('h1')?.textContent.trim() === 'Gallery' && document.querySelectorAll('.gallery-grid .gallery-item__button').length >= 5",
  }[path]
  if (!readiness) throw new Error(`No readiness condition exists for ${path}.`)
  return evaluate(`(async () => {
    const limit = performance.now() + ${timeout};
    while (true) {
      const oldDocumentIsGone = window.__prompt26aNavigationToken !== ${JSON.stringify(navigationToken)};
      const visible = (element) => element && element.getBoundingClientRect().width > 0 && element.getBoundingClientRect().height > 0;
      const heading = document.querySelector('h1');
      if (oldDocumentIsGone && document.readyState === 'complete' && visible(heading) && (${readiness})) {
        return performance.now();
      }
      if (performance.now() > limit) throw new Error('Timed out waiting for usable route ${path}');
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
  })()`)
}

async function navigateAndWait(path, { clearCache = false } = {}) {
  const token = `${runId}-${path}-${Math.random()}`
  await evaluate(`window.__prompt26aNavigationToken = ${JSON.stringify(token)}`)
  if (clearCache) {
    await command('Network.clearBrowserCache')
    await command('Storage.clearDataForOrigin', {
      origin: baseUrl,
      storageTypes: 'cache_storage,local_storage,session_storage',
    })
  }
  const cpuBefore = cpuSnapshot()
  const freeBefore = os.freemem()
  const loadEvent = waitForEvent('Page.loadEventFired')
  const started = performance.now()
  await command('Page.navigate', { url: `${baseUrl}${path}` })
  const [, usableAt] = await Promise.all([loadEvent, waitForPageReady(path, token)])
  const ended = performance.now()
  const navigationTiming = await evaluate(`(() => {
    const entry = performance.getEntriesByType('navigation')[0];
    return entry ? { load_event_end_ms: entry.loadEventEnd, dom_complete_ms: entry.domComplete, transfer_size_bytes: entry.transferSize } : null;
  })()`)
  const cpuAfter = cpuSnapshot()
  const freeAfter = os.freemem()
  return {
    elapsed_ms: round(ended - started),
    browser_usable_monotonic_ms: round(usableAt),
    navigation_timing: navigationTiming,
    system_cpu_percent: cpuPercent(cpuBefore, cpuAfter),
    available_memory_bytes_before: freeBefore,
    available_memory_bytes_after: freeAfter,
  }
}

async function setInput(selector, value) {
  await evaluate(`(() => {
    const element = document.querySelector(${JSON.stringify(selector)});
    if (!element) throw new Error('Missing input: ${selector}');
    const setter = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(element), 'value').set;
    setter.call(element, ${JSON.stringify(value)});
    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
  })()`)
}

async function waitForExpression(expression, label, timeout = 20000) {
  return evaluate(`(async () => {
    const limit = performance.now() + ${timeout};
    while (!(${expression})) {
      if (performance.now() > limit) throw new Error(${JSON.stringify(`Timed out waiting for ${label}.`)});
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
    return true;
  })()`)
}

async function clickByText(text) {
  await evaluate(`(() => {
    const button = [...document.querySelectorAll('button')].find((candidate) => candidate.textContent.trim() === ${JSON.stringify(text)});
    if (!button) throw new Error('Missing button: ${text}');
    button.click();
  })()`)
}

async function dispatchMeasuredClick(text) {
  const point = await evaluate(`(() => {
    const button = [...document.querySelectorAll('button')].find((candidate) => candidate.textContent.trim() === ${JSON.stringify(text)});
    if (!button || button.disabled) throw new Error('Measured action is unavailable: ${text}');
    button.scrollIntoView({ block: 'center', inline: 'center' });
    const rect = button.getBoundingClientRect();
    return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 };
  })()`)
  await sleep(20)
  const started = performance.now()
  await command('Input.dispatchMouseEvent', { type: 'mousePressed', x: point.x, y: point.y, button: 'left', clickCount: 1 })
  await command('Input.dispatchMouseEvent', { type: 'mouseReleased', x: point.x, y: point.y, button: 'left', clickCount: 1 })
  return started
}

async function installMutationObserver(pathSuffix) {
  await evaluate(`(() => {
    const originalFetch = window.fetch.bind(window);
    window.__prompt26aMutation = { completed: false, status: null, body: null };
    window.fetch = async (...args) => {
      const response = await originalFetch(...args);
      const url = String(args[0]);
      const method = String(args[1]?.method || 'GET').toUpperCase();
      if (url.endsWith(${JSON.stringify(pathSuffix)}) && method === 'POST') {
        const clone = response.clone();
        clone.json().then((body) => {
          window.__prompt26aMutation = { completed: true, status: response.status, body };
        });
      }
      return response;
    };
  })()`)
}

async function measureNewsletter(iteration) {
  await navigateAndWait('/')
  const email = `prompt26a-newsletter-${runId}-${iteration}@example.test`
  await setInput('#newsletter_first_name', 'Prompt')
  await setInput('#newsletter_middle_initial', 'A')
  await setInput('#newsletter_last_name', 'Performance')
  await setInput('#newsletter_email', email)
  await setInput('#newsletter_confirmation_email', email)
  await waitForExpression("document.querySelector('#newsletter-lookup-status')?.textContent.includes('No existing')", 'newsletter not-found lookup')
  await evaluate("document.querySelector('#newsletter_subscribed').click()")
  await installMutationObserver('/api/v1/newsletter-preferences')
  const cpuBefore = cpuSnapshot()
  const freeBefore = os.freemem()
  const started = await dispatchMeasuredClick('Save newsletter preference')
  await waitForExpression("window.__prompt26aMutation?.completed === true && document.querySelector('form[aria-label=\"Newsletter preferences\"]')?.getAttribute('aria-busy') === 'false' && [...document.querySelectorAll('.status-panel')].some((node) => node.textContent.includes('Newsletter preference saved'))", 'newsletter mutation response and rendered success')
  const ended = performance.now()
  const mutation = await evaluate('window.__prompt26aMutation')
  const cpuAfter = cpuSnapshot()
  const freeAfter = os.freemem()
  if (mutation.status !== 200 || mutation.body?.result !== 'set') throw new Error(`Newsletter sample ${iteration} was not an ordinary successful mutation.`)
  return {
    iteration,
    elapsed_ms: round(ended - started),
    http_status: mutation.status,
    result: mutation.body.result,
    system_cpu_percent: cpuPercent(cpuBefore, cpuAfter),
    available_memory_bytes_before: freeBefore,
    available_memory_bytes_after: freeAfter,
  }
}

async function prepareReservation(iteration, localDate) {
  await navigateAndWait('/reservations')
  await setInput('#local_date', localDate)
  await setInput('#party_size', '4')
  await clickByText('Check availability')
  await waitForExpression("document.querySelector('input[name=\"reservation_slot\"]:not(:disabled)')", 'available reservation slot')
  await evaluate("document.querySelector('input[name=\"reservation_slot\"]:not(:disabled)').click()")
  const email = `prompt26a-reservation-${runId}-${iteration}@example.test`
  await setInput('#first_name', 'Prompt')
  await setInput('#middle_initial', 'A')
  await setInput('#last_name', 'Performance')
  await setInput('#email', email)
  await setInput('#confirmation_email', email)
  await setInput('#phone', '+1 (202) 555-0126')
  await waitForExpression("[...document.querySelectorAll('[role=\"status\"]')].some((node) => node.textContent.includes('No existing newsletter'))", 'reservation newsletter lookup')
  await waitForExpression("[...document.querySelectorAll('button')].some((button) => button.textContent.trim() === 'Reserve table' && !button.disabled)", 'enabled reservation action')
  return email
}

async function measureReservation(iteration, localDate) {
  await prepareReservation(iteration, localDate)
  await installMutationObserver('/api/v1/reservations')
  const cpuBefore = cpuSnapshot()
  const freeBefore = os.freemem()
  const started = await dispatchMeasuredClick('Reserve table')
  await waitForExpression("window.__prompt26aMutation?.completed === true && document.querySelector('#confirmation-heading')?.textContent.includes('Reservation confirmed')", 'reservation mutation response and rendered confirmation', 25000)
  const ended = performance.now()
  const mutation = await evaluate('window.__prompt26aMutation')
  const cpuAfter = cpuSnapshot()
  const freeAfter = os.freemem()
  if (mutation.status !== 201 || mutation.body?.booking_result !== 'created') {
    throw new Error(`Reservation sample ${iteration} was not an ordinary successful creation: ${JSON.stringify(mutation)}`)
  }
  return {
    iteration,
    elapsed_ms: round(ended - started),
    http_status: mutation.status,
    booking_result: mutation.body.booking_result,
    reservation_reference: mutation.body.confirmation?.reservation_reference,
    system_cpu_percent: cpuPercent(cpuBefore, cpuAfter),
    available_memory_bytes_before: freeBefore,
    available_memory_bytes_after: freeAfter,
  }
}

function collectSystemSummary(allSamples, startFreeMemory) {
  const cpu = allSamples.map((sample) => sample.system_cpu_percent)
  const available = allSamples.flatMap((sample) => [sample.available_memory_bytes_before, sample.available_memory_bytes_after])
  return {
    cpu_sample_count: cpu.length,
    cpu_minimum_percent: round(Math.min(...cpu)),
    cpu_median_percent: round(median(cpu)),
    cpu_maximum_percent: round(Math.max(...cpu)),
    available_memory_at_measurement_start_bytes: startFreeMemory,
    minimum_available_memory_during_samples_bytes: Math.min(...available),
    maximum_used_physical_memory_during_samples_bytes: os.totalmem() - Math.min(...available),
  }
}

const results = {
  schema_version: 1,
  run_id: runId,
  measured_at_utc: new Date().toISOString(),
  basis: {
    concurrent_users: 1,
    sequential: true,
    network_throttling: 'none; actual unthrottled local VM path',
    cpu_throttling: 'none',
    browser_cache: 'warm application/server; Network.clearBrowserCache before every NFR-1 navigation',
  },
  route_readiness_conditions: {
    '/': 'document load complete; visible Café Fausse h1; live server-sourced current-hours content rendered',
    '/menu': 'document load complete; visible Menu h1; all four menu-category sections rendered',
    '/reservations': 'document load complete; visible Reservations h1; date control and server-authoritative ready status rendered',
    '/about': 'document load complete; visible About Us h1; story and founders sections rendered',
    '/gallery': 'document load complete; visible Gallery h1; at least five gallery image controls rendered',
  },
  nfr1: { threshold_ms: 3000, routes: {} },
  nfr2: { threshold_ms: 2000, newsletter: [], reservation: [] },
}

try {
  await command('Page.enable')
  await command('Runtime.enable')
  await command('Network.enable')
  await command('Performance.enable')

  await navigateAndWait('/')
  results.warmup = 'One unmeasured Home navigation completed after the stack was ready.'
  const measurementStartFreeMemory = os.freemem()

  for (const path of ['/', '/menu', '/reservations', '/about', '/gallery']) {
    const samples = []
    for (let iteration = 1; iteration <= 5; iteration += 1) {
      samples.push({ iteration, ...(await navigateAndWait(path, { clearCache: true })) })
    }
    results.nfr1.routes[path] = { samples, summary: summary(samples) }
  }
  const nfr1Samples = Object.values(results.nfr1.routes).flatMap((route) => route.samples)
  const worstNavigation = nfr1Samples.reduce((worst, sample) => sample.elapsed_ms > worst.elapsed_ms ? sample : worst)
  results.nfr1.global_maximum_ms = worstNavigation.elapsed_ms
  results.nfr1.pass = nfr1Samples.every((sample) => sample.elapsed_ms <= results.nfr1.threshold_ms)

  for (let iteration = 1; iteration <= 10; iteration += 1) {
    results.nfr2.newsletter.push(await measureNewsletter(iteration))
  }

  await navigateAndWait('/reservations')
  const minimumDate = await evaluate("document.querySelector('#local_date').min")
  const reservationDate = new Date(`${minimumDate}T12:00:00Z`)
  reservationDate.setUTCDate(reservationDate.getUTCDate() + 1)
  results.nfr2.reservation_local_date = reservationDate.toISOString().slice(0, 10)
  for (let iteration = 1; iteration <= 10; iteration += 1) {
    results.nfr2.reservation.push(await measureReservation(iteration, results.nfr2.reservation_local_date))
  }

  results.nfr2.newsletter_summary = summary(results.nfr2.newsletter, true)
  results.nfr2.reservation_summary = summary(results.nfr2.reservation, true)
  results.nfr2.newsletter_pass = results.nfr2.newsletter.every((sample) => sample.elapsed_ms <= results.nfr2.threshold_ms)
  results.nfr2.reservation_pass = results.nfr2.reservation.every((sample) => sample.elapsed_ms <= results.nfr2.threshold_ms)
  results.nfr2.pass = results.nfr2.newsletter_pass && results.nfr2.reservation_pass
  results.p95_method = 'Nearest-rank p95; with ten samples this is the maximum observation.'
  results.system_observations = collectSystemSummary(
    [...nfr1Samples, ...results.nfr2.newsletter, ...results.nfr2.reservation],
    measurementStartFreeMemory,
  )

  fs.mkdirSync(path.dirname(outputPath), { recursive: true })
  fs.writeFileSync(outputPath, `${JSON.stringify(results, null, 2)}\n`, 'utf8')
  console.log(JSON.stringify({ result: 'PASS', outputPath, nfr1: results.nfr1.pass, nfr2: results.nfr2.pass }))
} finally {
  socket.close()
}
