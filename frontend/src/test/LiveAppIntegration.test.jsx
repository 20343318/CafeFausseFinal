import { HttpResponse, http } from 'msw'
import { screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { cloneFixture, reservationContextFixture } from '../api/contractFixtures.js'
import { server } from './msw/server.js'
import { renderApp } from './test-utils.jsx'

describe('production App operation selection', () => {
  it('defaults to the live adapter', async () => {
    let requestCount = 0
    server.use(http.get('/api/v1/reservation-context', () => {
      requestCount += 1
      return HttpResponse.json(cloneFixture(reservationContextFixture))
    }))

    renderApp('/')
    expect(await screen.findByText('Monday: 5:00 PM–11:00 PM')).toBeInTheDocument()
    expect(requestCount).toBe(1)
  })

  it('retains explicit operation injection without dispatching the live request', async () => {
    const context = cloneFixture(reservationContextFixture)
    context.weekday_hours[6].closes_at_local = '20:00:00'
    const injected = {
      getReservationContext: vi.fn().mockResolvedValue(context),
      getReservationAvailability: vi.fn(),
      queryNewsletterStatus: vi.fn(),
      setNewsletterPreference: vi.fn(),
      createReservation: vi.fn(),
    }

    renderApp('/', injected)
    expect(await screen.findByText('Sunday: 5:00 PM–8:00 PM')).toBeInTheDocument()
    expect(injected.getReservationContext).toHaveBeenCalledTimes(1)
  })
})
