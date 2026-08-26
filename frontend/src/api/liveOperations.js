const JSON_CONTENT_TYPE = 'application/json'

export class ProtocolResponseError extends Error {
  constructor() {
    super('The API returned an invalid protocol response.')
    this.name = 'ProtocolResponseError'
    this.kind = 'protocol'
  }
}

export class PublicApiError extends Error {
  constructor(status, response) {
    super(response.error.code)
    this.name = 'PublicApiError'
    this.status = status
    this.response = response
  }
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function isPublicErrorEnvelope(value) {
  const error = value?.error
  return isObject(value)
    && isObject(error)
    && typeof error.code === 'string'
    && typeof error.message === 'string'
    && typeof error.retryable === 'boolean'
    && typeof error.outcome_unknown === 'boolean'
    && (error.fields === undefined || Array.isArray(error.fields))
}

async function parseJsonResponse(response) {
  let body
  try {
    body = await response.json()
  } catch {
    throw new ProtocolResponseError()
  }

  if (!response.ok) {
    if (!isPublicErrorEnvelope(body)) throw new ProtocolResponseError()
    throw new PublicApiError(response.status, body)
  }
  if (!isObject(body)) throw new ProtocolResponseError()
  return body
}

function get(path) {
  return fetch(path, { method: 'GET', cache: 'no-store' }).then(parseJsonResponse)
}

function post(path, body) {
  return fetch(path, {
    method: 'POST',
    cache: 'no-store',
    headers: { 'Content-Type': JSON_CONTENT_TYPE },
    body: JSON.stringify(body),
  }).then(parseJsonResponse)
}

export const liveOperationClient = Object.freeze({
  getReservationContext() {
    return get('/api/v1/reservation-context')
  },
  getReservationAvailability({ local_date, party_size }) {
    const query = new URLSearchParams([
      ['local_date', String(local_date)],
      ['party_size', String(party_size)],
    ])
    return get(`/api/v1/reservation-availability?${query.toString()}`)
  },
  queryNewsletterStatus(body) {
    return post('/api/v1/newsletter-status-queries', body)
  },
  setNewsletterPreference(body) {
    return post('/api/v1/newsletter-preferences', body)
  },
  createReservation(body) {
    return post('/api/v1/reservations', body)
  },
})
