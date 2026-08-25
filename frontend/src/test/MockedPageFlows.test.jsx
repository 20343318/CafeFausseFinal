import { fireEvent, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { http, HttpResponse } from 'msw'
import { describe, expect, it, vi } from 'vitest'
import { availabilityFixture, cloneFixture, confirmationFixture } from '../api/contractFixtures.js'
import { renderApp } from './test-utils.jsx'
import { mswOperationClient } from './msw/operationClient.js'
import { server } from './msw/server.js'

async function fillReservation() {
  fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
  fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
  await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
  await userEvent.click(await screen.findByRole('radio', { name: /5:00 PM.*Available/ }))
  await userEvent.type(screen.getByLabelText(/First name Required/), 'Ada')
  await userEvent.type(screen.getByLabelText(/Last name Required/), 'Rivera')
  await userEvent.type(screen.getByLabelText(/^Email Required/), 'ada.rivera@example.com')
  await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'ada.rivera@example.com')
}

async function fillNewsletterIdentity({ first = 'Ada', middle = '', last = 'Rivera', email = 'ada.rivera@example.com' } = {}) {
  await userEvent.type(screen.getByLabelText(/First name Required/), first)
  if (middle) await userEvent.type(screen.getByLabelText(/Middle initial Optional/), middle)
  await userEvent.type(screen.getByLabelText(/Last name Required/), last)
  await userEvent.type(screen.getByLabelText(/^Email Required/), email)
  await userEvent.type(screen.getByLabelText(/Confirm email Required/), email)
}

describe('MSW full-route mocked contract flows', () => {
  it('completes OP-01, OP-02, OP-03 and exact OP-05 happy path', async () => {
    let captured
    server.use(http.post('/api/v1/reservations', async ({ request }) => {
      captured = await request.json()
      return HttpResponse.json(cloneFixture(confirmationFixture), { status: 201 })
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: 'Reservation confirmed' })).toBeInTheDocument()
    expect(screen.getByText('2026-09-12T21:00:00Z')).toBeInTheDocument()
    expect(screen.getByText('2026-09-12T22:30:00Z')).toBeInTheDocument()
    expect(screen.getByText('Subscribed')).toBeInTheDocument()
    expect(captured).toEqual({ first_name: 'Ada', last_name: 'Rivera', email: 'ada.rivera@example.com', confirmation_email: 'ada.rivera@example.com', starts_at_local: '2026-09-12T17:00:00-04:00', utc_offset_minutes: -240, party_size: 4, newsletter_action: 'no_change' })
  })

  it('shows every all-unavailable OP-02 slot without making it selectable', async () => {
    server.use(http.get('/api/v1/reservation-availability', () => {
      const response = cloneFixture(availabilityFixture)
      response.slots.forEach((slot) => { slot.available = false })
      return HttpResponse.json(response)
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    expect(await screen.findByText(/All offered times are currently unavailable/)).toBeInTheDocument()
    expect(screen.getAllByRole('radio')).toHaveLength(10)
  })

  it('recovers an ambiguous reservation with an identical request and exact_retry', async () => {
    let calls = 0
    const bodies = []
    server.use(http.post('/api/v1/reservations', async ({ request }) => {
      bodies.push(await request.json())
      calls += 1
      if (calls === 1) return HttpResponse.json({ error: { code: 'reservation_outcome_unknown', message: 'Unknown.', retryable: true, outcome_unknown: true } }, { status: 503 })
      return HttpResponse.json({ ...cloneFixture(confirmationFixture), booking_result: 'exact_retry' })
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByText(/existing reservation was recovered/)).toBeInTheDocument()
    expect(bodies[1]).toEqual(bodies[0])
    expect(bodies).toHaveLength(2)
  })

  it('supersedes full-route outcome-unknown recovery when retry returns reservation_unavailable', async () => {
    let calls = 0
    server.use(http.post('/api/v1/reservations', () => {
      calls += 1
      const error = calls === 1
        ? { code: 'reservation_outcome_unknown', message: 'Unknown.', retryable: true, outcome_unknown: true }
        : { code: 'reservation_unavailable', message: 'Unavailable.', retryable: false, outcome_unknown: false }
      return HttpResponse.json({ error }, { status: calls === 1 ? 503 : 409 })
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Retry the same reservation' }))
    expect(await screen.findByRole('heading', { name: 'Reservation time unavailable' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Retry the same reservation' })).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Refresh times' })).toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeEnabled()
  })

  it('completes standalone newsletter no-customer/no-change through OP-03 and OP-04', async () => {
    renderApp('/', mswOperationClient)
    await userEvent.type(screen.getByLabelText(/First name Required/), 'New')
    await userEvent.type(screen.getByLabelText(/Last name Required/), 'Guest')
    await userEvent.type(screen.getByLabelText(/^Email Required/), 'new@example.com')
    await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'new@example.com')
    await waitFor(() => expect(screen.getByText(/No existing newsletter preference/)).toBeInTheDocument(), { timeout: 1500 })
    await userEvent.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText(/no new customer was created/)).toBeInTheDocument()
  })

  it('clears and focuses a selected slot that becomes unavailable after an MSW refresh', async () => {
    let call = 0
    server.use(http.get('/api/v1/reservation-availability', () => {
      const response = cloneFixture(availabilityFixture)
      if (++call === 2) response.slots[0].available = false
      return HttpResponse.json(response)
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    const alert = await screen.findByText(/selected time is no longer available/i)
    expect(alert).toHaveFocus()
    expect(screen.getByRole('radio', { name: /5:00 PM.*Unavailable/ })).not.toBeChecked()
  })

  it('suppresses stale OP-02 and invalidates schedule state on date and party edits', async () => {
    let releaseOld
    server.use(http.get('/api/v1/reservation-availability', async ({ request }) => {
      const url = new URL(request.url)
      if (url.searchParams.get('local_date') === '2026-09-12') return new Promise((resolve) => { releaseOld = () => resolve(HttpResponse.json(cloneFixture(availabilityFixture))) })
      return HttpResponse.json({ ...cloneFixture(availabilityFixture), local_date: '2026-09-13', slots: [] })
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-13' } })
    await userEvent.click(screen.getByRole('button', { name: 'Update times' }))
    expect(await screen.findByText(/No reservation times are offered/)).toBeInTheDocument()
    releaseOld()
    await Promise.resolve()
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '5' } })
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
  })

  it('covers customer validation, email mismatch, and OP-03 identity/middle conflicts with accessible focus', async () => {
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    fireEvent.change(screen.getByLabelText(/Reservation date Required/), { target: { value: '2026-09-12' } })
    fireEvent.change(screen.getByLabelText(/Party size Required/), { target: { value: '4' } })
    await userEvent.click(screen.getByRole('button', { name: 'Check availability' }))
    await userEvent.click(await screen.findByRole('radio', { name: /5:00 PM.*Available/ }))
    fireEvent.submit(screen.getByRole('form'))
    expect(await screen.findByRole('alert')).toHaveFocus()
    await userEvent.type(screen.getByLabelText(/First name Required/), 'Grace')
    await userEvent.type(screen.getByLabelText(/Last name Required/), 'Rivera')
    await userEvent.type(screen.getByLabelText(/^Email Required/), 'ada.rivera@example.com')
    await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'different@example.com')
    fireEvent.blur(screen.getByLabelText(/Confirm email Required/))
    expect(await screen.findByText('Email addresses must match.')).toBeInTheDocument()
    await userEvent.clear(screen.getByLabelText(/Confirm email Required/)); await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'ada.rivera@example.com')
    expect(await screen.findByText(/identity details do not match/i, {}, { timeout: 1500 })).toBeInTheDocument()
    await userEvent.clear(screen.getByLabelText(/First name Required/)); await userEvent.type(screen.getByLabelText(/First name Required/), 'Ada')
    await userEvent.type(screen.getByLabelText(/Middle initial Optional/), 'Q')
    expect(await screen.findByText(/identity details do not match/i, {}, { timeout: 1500 })).toBeInTheDocument()
  })

  it('covers OP-03 matched, not-found, indeterminate, stale, and deliberate-dirty protection', async () => {
    let releaseOld
    server.use(http.post('/api/v1/newsletter-status-queries', async ({ request }) => {
      const body = await request.json()
      if (body.email === 'ada.rivera@example.com') return new Promise((resolve) => { releaseOld = () => resolve(HttpResponse.json({ status: 'matched', subscribed: false })) })
      if (body.email === 'new@example.com') return HttpResponse.json({ status: 'not_found' })
      return HttpResponse.json({ error: { code: 'newsletter_status_indeterminate', message: 'Unavailable.', retryable: true, outcome_unknown: false } }, { status: 503 })
    }))
    renderApp('/', mswOperationClient)
    await fillNewsletterIdentity()
    await waitFor(() => expect(releaseOld).toBeTypeOf('function'), { timeout: 1500 })
    await userEvent.click(screen.getByRole('checkbox'))
    await userEvent.clear(screen.getByLabelText(/^Email Required/)); await userEvent.type(screen.getByLabelText(/^Email Required/), 'new@example.com')
    await userEvent.clear(screen.getByLabelText(/Confirm email Required/)); await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'new@example.com')
    expect(await screen.findByText(/No existing newsletter preference/)).toBeInTheDocument()
    releaseOld()
    await waitFor(() => expect(screen.getByRole('checkbox')).toBeChecked())
    await userEvent.clear(screen.getByLabelText(/^Email Required/)); await userEvent.type(screen.getByLabelText(/^Email Required/), 'indeterminate@example.com')
    await userEvent.clear(screen.getByLabelText(/Confirm email Required/)); await userEvent.type(screen.getByLabelText(/Confirm email Required/), 'indeterminate@example.com')
    expect(await screen.findByRole('button', { name: 'Retry newsletter status' }, { timeout: 1500 })).toBeInTheDocument()
  })

  it('continues a reservation with no_change after indeterminate status and suppresses double submit', async () => {
    let resolveBooking
    const bodies = []
    server.use(
      http.post('/api/v1/newsletter-status-queries', () => HttpResponse.json({ error: { code: 'newsletter_status_indeterminate', message: 'Unavailable.', retryable: true, outcome_unknown: false } }, { status: 503 })),
      http.post('/api/v1/reservations', async ({ request }) => {
        bodies.push(await request.json())
        return new Promise((resolve) => { resolveBooking = () => resolve(HttpResponse.json(cloneFixture(confirmationFixture), { status: 201 })) })
      }),
    )
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await screen.findByRole('button', { name: 'Retry newsletter status' }, { timeout: 1500 })
    const submit = screen.getByRole('button', { name: 'Reserve table' })
    await userEvent.click(submit)
    fireEvent.submit(submit.closest('form'))
    expect(bodies).toHaveLength(1)
    expect(bodies[0].newsletter_action).toBe('no_change')
    resolveBooking()
    expect(await screen.findByRole('heading', { name: 'Reservation confirmed' })).toBeInTheDocument()
  })

  it.each([
    ['reservation_unavailable', 409, false, 'Reservation time unavailable', 'Refresh times'],
    ['reservation_overlap', 409, false, 'Choose another time', null],
    ['temporary_failure', 503, true, 'Reservation could not be processed', 'Retry the same reservation'],
    ['reservation_confirmation_unavailable', 503, true, 'Reservation exists; confirmation unavailable', 'Retry the same reservation'],
  ])('maps full-route %s recovery exactly', async (code, status, retryable, title, action) => {
    let calls = 0
    server.use(http.post('/api/v1/reservations', () => {
      calls += 1
      if (calls === 1) return HttpResponse.json({ error: { code, message: 'Mutable.', retryable, outcome_unknown: false } }, { status })
      return HttpResponse.json({ ...cloneFixture(confirmationFixture), booking_result: 'exact_retry' })
    }))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: title })).toBeInTheDocument()
    if (action) expect(screen.getByRole('button', { name: action })).toBeInTheDocument()
    if (action === 'Retry the same reservation') {
      await userEvent.click(screen.getByRole('button', { name: action }))
      expect(await screen.findByText(/existing reservation was recovered/i)).toBeInTheDocument()
    }
  })

  it('treats an MSW transport loss as conservative reservation ambiguity', async () => {
    server.use(http.post('/api/v1/reservations', () => HttpResponse.error()))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    expect(await screen.findByRole('heading', { name: 'Reservation result not confirmed' })).toBeInTheDocument()
  })

  it('uses OP-05 validation field/code metadata to invalidate stale availability and focus recovery', async () => {
    server.use(http.post('/api/v1/reservations', () => HttpResponse.json({ error: { code: 'validation_failed', message: 'Mutable.', retryable: false, outcome_unknown: false, fields: [{ field: 'starts_at_local', code: 'invalid_reservation_time', message: 'Mutable field wording.' }] } }, { status: 422 })))
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    await fillReservation()
    await userEvent.click(screen.getByRole('button', { name: 'Reserve table' }))
    const recovery = await screen.findByText(/submitted schedule is no longer current/i)
    expect(recovery).toHaveFocus()
    expect(screen.queryByRole('radio')).not.toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toHaveValue('Ada')
  })

  it.each([
    [true, 'set', /Authoritative preference: subscribed/],
    [false, 'set', /Authoritative preference: not subscribed/],
  ])('saves standalone matched %s preference authoritatively', async (desired, result, copy) => {
    renderApp('/', mswOperationClient)
    await fillNewsletterIdentity()
    await waitFor(() => expect(screen.getByText(/Current preference: subscribed/)).toBeInTheDocument(), { timeout: 1500 })
    if (!desired) await userEvent.click(screen.getByRole('checkbox'))
    await userEvent.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText(copy)).toBeInTheDocument()
    expect(screen.getByText(`Current preference: ${desired ? 'subscribed' : 'not subscribed'}.`)).toBeInTheDocument()
    expect(result).toBe('set')
  })

  it('covers standalone known failure and outcome-unknown identical recovery', async () => {
    let calls = 0
    const bodies = []
    server.use(http.post('/api/v1/newsletter-preferences', async ({ request }) => {
      bodies.push(await request.json())
      calls += 1
      if (calls === 1) return HttpResponse.json({ error: { code: 'internal_error', message: 'Known.', retryable: false, outcome_unknown: false } }, { status: 500 })
      if (calls === 2) return HttpResponse.json({ error: { code: 'newsletter_preference_outcome_unknown', message: 'Unknown.', retryable: true, outcome_unknown: true } }, { status: 503 })
      return HttpResponse.json({ result: 'set', subscribed: true })
    }))
    renderApp('/', mswOperationClient)
    await fillNewsletterIdentity()
    await userEvent.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByRole('heading', { name: 'Newsletter preference not saved' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Resend the same preference' })).not.toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Resend the same preference' }))
    expect(await screen.findByText(/Authoritative preference: subscribed/)).toBeInTheDocument()
    expect(bodies[2]).toEqual(bodies[1])
  })

  it('supersedes full-route newsletter outcome-unknown recovery with a definitive conflict', async () => {
    let calls = 0
    server.use(http.post('/api/v1/newsletter-preferences', () => {
      calls += 1
      const error = calls === 1
        ? { code: 'newsletter_preference_outcome_unknown', message: 'Unknown.', retryable: true, outcome_unknown: true }
        : { code: 'customer_identity_conflict', message: 'Conflict.', retryable: false, outcome_unknown: false }
      return HttpResponse.json({ error }, { status: calls === 1 ? 503 : 409 })
    }))
    renderApp('/', mswOperationClient)
    await fillNewsletterIdentity()
    await userEvent.click(screen.getByRole('checkbox'))
    await userEvent.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    await userEvent.click(await screen.findByRole('button', { name: 'Resend the same preference' }))
    expect(await screen.findByRole('alert')).toHaveFocus()
    expect(screen.queryByRole('button', { name: 'Resend the same preference' })).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Save newsletter preference' })).toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeEnabled()
  })

  it('covers responsive navigation state used alongside narrow full-route forms', async () => {
    const listeners = []
    window.matchMedia = vi.fn().mockReturnValue({ matches: false, addEventListener: (_type, listener) => listeners.push(listener), removeEventListener: vi.fn() })
    renderApp('/reservations', mswOperationClient)
    await screen.findByText('Reservation options are ready.')
    const menu = screen.getByRole('button', { name: 'Menu' })
    await userEvent.click(menu)
    expect(menu).toHaveAttribute('aria-expanded', 'true')
    listeners.forEach((listener) => listener({ matches: true }))
    await waitFor(() => expect(menu).toHaveAttribute('aria-expanded', 'false'))
  })
})
