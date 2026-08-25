import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'
import { cloneFixture, reservationContextFixture, resolveAvailability, resolveNewsletterPreference, resolveNewsletterStatus, resolveReservation } from '../../api/contractFixtures.js'

function contractResponse(callback, status = 200) {
  try {
    return HttpResponse.json(callback(), { status })
  } catch (cause) {
    return HttpResponse.json(cause.response, { status: cause.status })
  }
}

export const contractHandlers = [
  http.get('/api/v1/reservation-context', () => HttpResponse.json(cloneFixture(reservationContextFixture))),
  http.get('/api/v1/reservation-availability', ({ request }) => {
    const url = new URL(request.url)
    return contractResponse(() => resolveAvailability({ local_date: url.searchParams.get('local_date'), party_size: Number(url.searchParams.get('party_size')) }))
  }),
  http.post('/api/v1/newsletter-status-queries', async ({ request }) => {
    const body = await request.json()
    return contractResponse(() => resolveNewsletterStatus(body))
  }),
  http.post('/api/v1/newsletter-preferences', async ({ request }) => {
    const body = await request.json()
    return contractResponse(() => resolveNewsletterPreference(body))
  }),
  http.post('/api/v1/reservations', async ({ request }) => {
    const body = await request.json()
    return contractResponse(() => resolveReservation(body), 201)
  }),
]

export const server = setupServer(...contractHandlers)
