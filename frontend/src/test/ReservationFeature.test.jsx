import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { availabilityFixture, cloneFixture, confirmationFixture, publicApiError, reservationContextFixture } from '../api/contractFixtures.js'
import { renderApp } from './test-utils.jsx'

function operations(overrides = {}) {
  return {
    getReservationContext: vi.fn().mockResolvedValue(cloneFixture(reservationContextFixture)),
    getReservationAvailability: vi.fn().mockResolvedValue(cloneFixture(availabilityFixture)),
    queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'not_found' }),
    setNewsletterPreference: vi.fn().mockResolvedValue({ result: 'set', subscribed: true }),
    createReservation: vi.fn().mockResolvedValue(cloneFixture(confirmationFixture)),
    ...overrides,
  }
}

async function ready(client = operations()) {
  renderApp('/reservations', client)
  await screen.findByText('Reservation options are ready.')
  return client
}

async function selectSlot(client) {
  fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
  fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
  await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
  await screen.findByRole('radio', { name: /5:00 PM.*Available/ })
  await userEvent.click(screen.getByRole('radio', { name: /5:00 PM.*Available/ }))
  return client
}

async function fillIdentity() {
  await userEvent.type(screen.getByLabelText(/First name Required/), 'Ada')
  await userEvent.type(screen.getByLabelText(/Last name Required/), 'Rivera')
  await userEvent.type(screen.getByLabelText(/^Email Required/), 'ada.rivera@example.com')
  await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'ada.rivera@example.com')
}

async function readyToSubmit(client = operations()) {
  await ready(client)
  await selectSlot(client)
  await fillIdentity()
  await waitFor(() => expect(screen.getByRole('button', { name: 'Reserve table' })).toBeEnabled())
  return client
}

describe('reservation context and availability', () => {
  it('keeps the date and party fields in the shared alignment grid without changing their accessible order', async () => {
    await ready()
    const date = screen.getByLabelText(/Reservation date Required/)
    const party = screen.getByLabelText(/Party size Required/)
    const dateField = date.closest('.form-field')
    const partyField = party.closest('.form-field')
    const choiceGrid = dateField.closest('.choice-grid')

    expect(Array.from(choiceGrid.children)).toEqual([dateField, partyField])
    expect(date.previousElementSibling).toHaveAttribute('id', 'local_date-help')
    expect(party.previousElementSibling).toHaveAttribute('id', 'party_size-help')
    expect(date).toHaveAttribute('aria-describedby', 'local_date-help')
    expect(party).toHaveAttribute('aria-describedby', 'party_size-help')
    expect(choiceGrid.nextElementSibling).toBe(screen.getByRole('button', { name: 'Check availability' }))
  })

  it('loads context and applies authoritative native bounds', async () => {
    await ready()
    expect(screen.getByLabelText(/Reservation date Required/)).toHaveAttribute('min', '2026-08-24')
    expect(screen.getByLabelText(/Reservation date Required/)).toHaveAttribute('max', '2026-10-23')
    expect(screen.getByLabelText(/Party size Required/)).toHaveAttribute('max', '120')
    expect(screen.getByText(/America\/New_York/)).toBeInTheDocument()
    const hours = document.querySelector('.dining-hours')
    const rows = hours.querySelectorAll('.dining-hours__row')
    expect(hours.querySelector('summary')).toHaveTextContent('Current dining hours')
    expect(rows).toHaveLength(7)
    expect(rows[0]).toHaveTextContent('Monday:5:00 PM–11:00 PM')
    expect(rows[2]).toHaveTextContent('Wednesday:5:00 PM–11:00 PM')
    expect(rows[2].querySelector('.dining-hours__time')).toHaveTextContent('5:00 PM–11:00 PM')
  })

  it('blocks controls on context failure and retries OP-01', async () => {
    const client = operations({ getReservationContext: vi.fn().mockRejectedValueOnce(publicApiError('service_unavailable')).mockResolvedValueOnce(cloneFixture(reservationContextFixture)) })
    renderApp('/reservations', client)
    expect(await screen.findByRole('alert')).toHaveTextContent('Reservation options are unavailable')
    expect(screen.queryByLabelText(/Reservation date Required/)).not.toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Try again' }))
    expect(await screen.findByLabelText(/Reservation date Required/)).toBeInTheDocument()
  })

  it('requests availability explicitly, preserves API order, and disables unavailable slots', async () => {
    const client = await ready()
    await selectSlot(client)
    expect(client.getReservationAvailability).toHaveBeenCalledWith({ local_date: '2026-09-12', party_size: 4 })
    const radios = screen.getAllByRole('radio')
    expect(radios).toHaveLength(10)
    expect(radios[0]).toBeChecked()
    expect(radios[2]).toBeDisabled()
  })

  it('renders fully unavailable and empty schedules as valid states', async () => {
    const allUnavailable = cloneFixture(availabilityFixture)
    allUnavailable.slots.forEach((slot) => { slot.available = false })
    const client = operations({ getReservationAvailability: vi.fn().mockResolvedValueOnce(allUnavailable).mockResolvedValueOnce({ ...allUnavailable, slots: [] }) })
    await ready(client)
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    expect(await screen.findByText(/All offered times are currently unavailable/)).toBeInTheDocument()
    expect(screen.getAllByRole('radio').every((radio) => radio.disabled)).toBe(true)
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    expect(await screen.findByText(/No reservation times are offered/)).toBeInTheDocument()
  })

  it('invalidates availability and selection when date or party changes', async () => {
    await readyToSubmit()
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '5' } })
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Reserve table' })).toBeDisabled()
    expect(screen.getByLabelText(/First name Required/)).toHaveValue('Ada')
  })

  it('ignores a stale late OP-02 completion', async () => {
    let resolveOld
    const old = new Promise((resolve) => { resolveOld = resolve })
    const newer = { ...cloneFixture(availabilityFixture), local_date: '2026-09-13', slots: [] }
    const client = operations({ getReservationAvailability: vi.fn().mockReturnValueOnce(old).mockResolvedValueOnce(newer) })
    await ready(client)
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-13' } })
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    expect(await screen.findByText(/No reservation times are offered/)).toBeInTheDocument()
    resolveOld(cloneFixture(availabilityFixture))
    await Promise.resolve()
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
  })

  it('clears and focuses required action when refresh removes the selected slot', async () => {
    const refreshed = cloneFixture(availabilityFixture)
    refreshed.slots[0].available = false
    const client = operations({ getReservationAvailability: vi.fn().mockResolvedValueOnce(cloneFixture(availabilityFixture)).mockResolvedValueOnce(refreshed) })
    await ready(client)
    await selectSlot(client)
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    const alert = await screen.findByText(/selected time is no longer available/i)
    expect(alert).toHaveFocus()
    expect(screen.getByRole('radio', { name: /5:00 PM.*Unavailable/ })).not.toBeChecked()
  })

  it('offers OP-02 retry only for transport or explicitly retryable errors', async () => {
    const client = operations({ getReservationAvailability: vi.fn()
      .mockRejectedValueOnce(publicApiError('validation_failed', { status: 422 }))
      .mockRejectedValueOnce(publicApiError('service_unavailable', { retryable: true }))
      .mockResolvedValueOnce(cloneFixture(availabilityFixture)) })
    await ready(client)
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    expect(await screen.findByText(/cannot be retried unchanged/)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Try again' })).not.toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    expect(await screen.findByRole('button', { name: 'Try again' })).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Try again' }))
    expect(await screen.findByRole('radio', { name: /5:00 PM.*Available/ })).toBeInTheDocument()
  })
})

describe('reservation customer, submission, and recovery', () => {
  it('shows touched errors and focuses a linked summary on invalid submission', async () => {
    await ready()
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    await userEvent.click(await screen.findByRole('radio', { name: /5:00 PM.*Available/ }))
    fireEvent.submit(screen.getByRole('form'))
    const summary = await screen.findByRole('alert')
    expect(summary).toHaveFocus()
    expect(within(summary).getByRole('link', { name: /First name/ })).toHaveAttribute('href', '#first_name')
  })

  it('associates email mismatch with Confirm email and preserves both entries', async () => {
    await ready()
    await userEvent.type(screen.getByLabelText(/^Email Required/), 'ada@example.com')
    await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'other@example.com')
    fireEvent.blur(screen.getByLabelText(/Confirm email Required/))
    expect(await screen.findByText('Email addresses must match.')).toBeInTheDocument()
    expect(screen.getByLabelText(/Confirm email Required/)).toHaveValue('other@example.com')
  })

  it('submits the immutable exact OP-05 body once and renders public confirmation', async () => {
    let resolveBooking
    const booking = new Promise((resolve) => { resolveBooking = resolve })
    const client = operations({ createReservation: vi.fn().mockReturnValue(booking) })
    await readyToSubmit(client)
    const button = screen.getByRole('button', { name: 'Reserve table' })
    await userEvent.click(button)
    expect(screen.getByRole('button', { name: /Reserving/ })).toBeDisabled()
    fireEvent.submit(button.closest('form'))
    expect(client.createReservation).toHaveBeenCalledTimes(1)
    expect(client.createReservation.mock.calls[0][0]).toEqual({ first_name: 'Ada', last_name: 'Rivera', email: 'ada.rivera@example.com', confirmation_email: 'ada.rivera@example.com', starts_at_local: '2026-09-12T17:00:00-04:00', utc_offset_minutes: -240, party_size: 4, newsletter_action: 'no_change' })
    expect(Object.isFrozen(client.createReservation.mock.calls[0][0])).toBe(true)
    resolveBooking(cloneFixture(confirmationFixture))
    const heading = await screen.findByRole('heading', { name: 'Reservation confirmed' })
    expect(heading).toHaveFocus()
    expect(screen.getByText('9007199254740993')).toBeInTheDocument()
    expect(screen.getByText('September 12, 2026 at 5:00 PM Eastern Time')).toBeInTheDocument()
    expect(screen.getByText('September 12, 2026 at 6:30 PM Eastern Time')).toBeInTheDocument()
    expect(screen.queryByText(confirmationFixture.confirmation.starts_at)).not.toBeInTheDocument()
    expect(screen.queryByText(confirmationFixture.confirmation.ends_at)).not.toBeInTheDocument()
    expect(screen.getByText('7')).toBeInTheDocument()
    expect(screen.queryByText('ada.rivera@example.com')).not.toBeInTheDocument()
  })

  it('submits a valid one-letter middle initial unchanged', async () => {
    const client = await readyToSubmit()
    await userEvent.type(screen.getByLabelText(/Middle initial Optional/), 'A')
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(client.createReservation).toHaveBeenCalledWith(expect.objectContaining({ middle_initial: 'A' }))
  })

  it.each([
    ['reservation_overlap', 'Choose another time'],
    ['reservation_unavailable', 'Reservation time unavailable'],
    ['customer_identity_conflict', 'Identity details do not match'],
    ['middle_initial_conflict', 'Middle initial needs attention'],
  ])('maps %s by public code', async (code, title) => {
    const client = operations({ createReservation: vi.fn().mockRejectedValue(publicApiError(code, { status: 409 })) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: title })).toBeInTheDocument()
  })

  it('retains an exact snapshot for known temporary retry', async () => {
    const client = operations({ createReservation: vi.fn().mockRejectedValueOnce(publicApiError('temporary_failure', { retryable: true })).mockResolvedValueOnce({ ...cloneFixture(confirmationFixture), booking_result: 'exact_retry' }) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByText(/existing reservation was recovered/i)).toBeInTheDocument()
    expect(client.createReservation.mock.calls[1][0]).toBe(client.createReservation.mock.calls[0][0])
  })

  it.each([
    ['reservation_confirmation_unavailable', false, 'Reservation exists; confirmation unavailable'],
    ['reservation_outcome_unknown', true, 'Reservation result not confirmed'],
  ])('handles %s with locked identical recovery', async (code, outcomeUnknown, title) => {
    const client = operations({ createReservation: vi.fn().mockRejectedValueOnce(publicApiError(code, { retryable: true, outcomeUnknown })).mockResolvedValueOnce({ ...cloneFixture(confirmationFixture), booking_result: 'exact_retry' }) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: title })).toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeDisabled()
    await userEvent.click(screen.getByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByRole('heading', { name: 'Reservation confirmed' })).toBeInTheDocument()
    expect(client.createReservation.mock.calls[1][0]).toBe(client.createReservation.mock.calls[0][0])
  })

  it('treats an unclassified transport loss as outcome unknown', async () => {
    const client = operations({ createReservation: vi.fn().mockRejectedValue(new TypeError('Failed to fetch')) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: 'Reservation result not confirmed' })).toBeInTheDocument()
  })

  it('invalidates the complete stale schedule by exact server field/code and focuses recovery', async () => {
    const fields = [{ field: 'starts_at_local', code: 'utc_offset_mismatch', message: 'Mutable wording that must not drive recovery.' }]
    const client = operations({ createReservation: vi.fn().mockRejectedValue(publicApiError('validation_failed', { status: 422, fields })) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    const recovery = await screen.findByText(/submitted schedule is no longer current/i)
    expect(recovery).toHaveFocus()
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toHaveValue('Ada')
    expect(screen.getByRole('button', { name: 'Reserve table' })).toBeDisabled()
  })

  it('does not offer or describe retry for a known non-retryable generic reservation error', async () => {
    const client = operations({ createReservation: vi.fn().mockRejectedValue(publicApiError('internal_error', { status: 500 })) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByText(/No identical retry action is available/)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Retry the same reservation' })).not.toBeInTheDocument()
  })

  it('supersedes outcome-unknown recovery when identical retry returns reservation_unavailable', async () => {
    const client = operations({ createReservation: vi.fn()
      .mockRejectedValueOnce(publicApiError('reservation_outcome_unknown', { retryable: true, outcomeUnknown: true }))
      .mockRejectedValueOnce(publicApiError('reservation_unavailable', { status: 409 })) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByRole('heading', { name: 'Reservation time unavailable' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Retry the same reservation' })).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Refresh times' })).toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeEnabled()
    await userEvent.click(screen.getByRole('button', { name: 'Refresh times' }))
    expect(await screen.findByRole('radio', { name: /5:00 PM.*Available/ })).toBeInTheDocument()
  })

  it.each([
    ['customer_identity_conflict', publicApiError('customer_identity_conflict', { status: 409 }), 'Identity details do not match'],
    ['validation_failed', publicApiError('validation_failed', { status: 422, fields: [{ field: 'first_name', code: 'invalid_normalized_input', message: 'Enter a valid first name.' }] }), 'Please review the fields below.'],
  ])('clears stale recovery when identical retry returns definitive %s', async (_code, definitive, expected) => {
    const client = operations({ createReservation: vi.fn()
      .mockRejectedValueOnce(publicApiError('temporary_failure', { retryable: true }))
      .mockRejectedValueOnce(definitive) })
    await readyToSubmit(client)
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByText(expected)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Retry the same reservation' })).not.toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeEnabled()
  })

  it('constrains Middle initial to one input character', async () => {
    await ready()
    expect(screen.getByLabelText(/First name Required/)).not.toHaveAttribute('maxlength')
    expect(screen.getByLabelText(/Middle initial Optional/)).toHaveAttribute('maxlength', '1')
    expect(screen.getByLabelText(/Last name Required/)).not.toHaveAttribute('maxlength')
  })
})
