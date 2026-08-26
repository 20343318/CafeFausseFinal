import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { cloneFixture, reservationContextFixture } from '../api/contractFixtures.js'
import { renderApp } from './test-utils.jsx'

function client(getReservationContext) {
  return {
    getReservationContext,
    getReservationAvailability: vi.fn(),
    queryNewsletterStatus: vi.fn(),
    setNewsletterPreference: vi.fn(),
    createReservation: vi.fn(),
  }
}

describe('Home CurrentHours server authority', () => {
  it('renders all seven live OP-01 rows and reflects a server-side schedule change', async () => {
    const context = cloneFixture(reservationContextFixture)
    context.weekday_hours[0] = { iso_weekday: 1, opens_at_local: '18:30:00', closes_at_local: '22:00:00' }
    renderApp('/', client(vi.fn().mockResolvedValue(context)))

    expect(await screen.findByText('Monday: 6:30 PM–10:00 PM')).toBeInTheDocument()
    expect(screen.getByText('Sunday: 5:00 PM–9:00 PM')).toBeInTheDocument()
    expect(document.querySelector('[data-current-hours-source="reservation-context"]')).toBeInTheDocument()
  })

  it('shows no fallback schedule after failure and explicitly retries OP-01', async () => {
    const user = userEvent.setup()
    const getReservationContext = vi.fn()
      .mockRejectedValueOnce(new TypeError('offline'))
      .mockResolvedValueOnce(cloneFixture(reservationContextFixture))
    renderApp('/', client(getReservationContext))

    expect(await screen.findByRole('alert')).toHaveTextContent('No schedule has been assumed')
    expect(screen.queryByText('Monday: 5:00 PM–11:00 PM')).not.toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Try again' }))
    await waitFor(() => expect(getReservationContext).toHaveBeenCalledTimes(2))
    expect(await screen.findByText('Monday: 5:00 PM–11:00 PM')).toBeInTheDocument()
  })
})
