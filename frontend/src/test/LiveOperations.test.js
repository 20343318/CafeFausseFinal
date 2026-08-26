import { afterEach, describe, expect, it, vi } from 'vitest'
import { ProtocolResponseError, PublicApiError, liveOperationClient } from '../api/liveOperations.js'

function jsonResponse(body, { ok = true, status = 200 } = {}) {
  return { ok, status, json: vi.fn().mockResolvedValue(body) }
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('production live operation adapter', () => {
  it('uses exact same-origin GET paths and URI-encoded OP-02 query values', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ ok: true }))
    vi.stubGlobal('fetch', fetchMock)

    await liveOperationClient.getReservationContext()
    await liveOperationClient.getReservationAvailability({ local_date: '2026-09-12 & later', party_size: 4 })

    expect(fetchMock).toHaveBeenNthCalledWith(1, '/api/v1/reservation-context', { method: 'GET', cache: 'no-store' })
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      '/api/v1/reservation-availability?local_date=2026-09-12+%26+later&party_size=4',
      { method: 'GET', cache: 'no-store' },
    )
  })

  it.each([
    ['queryNewsletterStatus', '/api/v1/newsletter-status-queries'],
    ['setNewsletterPreference', '/api/v1/newsletter-preferences'],
    ['createReservation', '/api/v1/reservations'],
  ])('sends the exact %s JSON body to its frozen POST path', async (method, path) => {
    const body = Object.freeze({ first_name: 'Prompt', last_name: 'Twentyfour', email: 'prompt24@example.test' })
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ result: 'ok' }))
    vi.stubGlobal('fetch', fetchMock)

    await liveOperationClient[method](body)

    expect(fetchMock).toHaveBeenCalledWith(path, {
      method: 'POST',
      cache: 'no-store',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
  })

  it('returns a successful parsed public response unchanged', async () => {
    const body = { status: 'matched', subscribed: true }
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(body)))
    await expect(liveOperationClient.queryNewsletterStatus({})).resolves.toBe(body)
  })

  it('preserves HTTP status and the complete API-02 public error envelope', async () => {
    const response = {
      error: {
        code: 'validation_failed',
        message: 'One or more fields need attention.',
        retryable: false,
        outcome_unknown: false,
        fields: [{ field: 'party_size', code: 'out_of_range', message: 'Correct this field.' }],
      },
    }
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(jsonResponse(response, { ok: false, status: 422 })))

    const error = await liveOperationClient.createReservation({}).catch((cause) => cause)
    expect(error).toBeInstanceOf(PublicApiError)
    expect(error.status).toBe(422)
    expect(error.response).toBe(response)
  })

  it.each([
    jsonResponse(null),
    jsonResponse([], { ok: false, status: 503 }),
    { ok: true, status: 200, json: vi.fn().mockRejectedValue(new SyntaxError('not json')) },
  ])('classifies malformed or non-JSON HTTP results as protocol defects', async (response) => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response))
    await expect(liveOperationClient.getReservationContext()).rejects.toBeInstanceOf(ProtocolResponseError)
  })

  it.each(['getReservationContext', 'setNewsletterPreference', 'createReservation'])('preserves native transport rejection for %s', async (method) => {
    const transportFailure = new TypeError('Failed to fetch')
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(transportFailure))
    const argument = method === 'getReservationContext' ? undefined : {}
    await expect(liveOperationClient[method](argument)).rejects.toBe(transportFailure)
  })
})
