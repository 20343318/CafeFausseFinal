import { act, fireEvent, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { publicApiError, reservationContextFixture } from '../api/contractFixtures.js'
import { renderApp } from './test-utils.jsx'

function client(overrides = {}) {
  return {
    getReservationContext: vi.fn().mockResolvedValue(reservationContextFixture),
    getReservationAvailability: vi.fn(),
    queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'not_found' }),
    setNewsletterPreference: vi.fn().mockResolvedValue({ result: 'set', subscribed: true }),
    createReservation: vi.fn(),
    ...overrides,
  }
}

async function fillNewsletter() {
  const user = userEvent.setup()
  await user.type(screen.getByLabelText(/First name Required/), 'Ada')
  await user.type(screen.getByLabelText(/Last name Required/), 'Rivera')
  await user.type(screen.getByLabelText(/^Email Required/), 'ada@example.com')
  await user.type(screen.getByLabelText(/Confirm email Required/), 'ada@example.com')
  return user
}

describe('standalone newsletter preferences', () => {
  it('uses the frozen 400 ms eligible lookup debounce', async () => {
    vi.useFakeTimers()
    const api = client()
    renderApp('/', api)
    const values = [
      [/First name Required/, 'Ada'], [/Last name Required/, 'Rivera'], [/^Email Required/, 'ada@example.com'], [/Confirm email Required/, 'ada@example.com'],
    ]
    for (const [label, value] of values) {
      fireEvent.change(screen.getByLabelText(label), { target: { value } })
    }
    await act(() => vi.advanceTimersByTimeAsync(399))
    expect(api.queryNewsletterStatus).not.toHaveBeenCalled()
    await act(() => vi.advanceTimersByTimeAsync(1))
    expect(api.queryNewsletterStatus).toHaveBeenCalledTimes(1)
    vi.useRealTimers()
  })

  it('synchronizes an untouched matched choice', async () => {
    const api = client({ queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'matched', subscribed: true }) })
    renderApp('/', api)
    await fillNewsletter()
    await waitFor(() => expect(screen.getByRole('checkbox')).toBeChecked(), { timeout: 1500 })
    expect(screen.getByRole('status')).toHaveTextContent('Current preference: subscribed')
  })

  it('never overwrites a deliberate choice with a late lookup', async () => {
    let resolveLookup
    const api = client({ queryNewsletterStatus: vi.fn().mockReturnValue(new Promise((resolve) => { resolveLookup = resolve })) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await user.click(screen.getByRole('checkbox'))
    await waitFor(() => expect(api.queryNewsletterStatus).toHaveBeenCalled(), { timeout: 1500 })
    resolveLookup({ status: 'matched', subscribed: false })
    await waitFor(() => expect(screen.getByRole('checkbox')).toBeChecked())
    expect(screen.getByText(/choice is retained/i)).toBeInTheDocument()
  })

  it('ignores a stale identity lookup', async () => {
    let resolveOld
    const api = client({ queryNewsletterStatus: vi.fn().mockReturnValueOnce(new Promise((resolve) => { resolveOld = resolve })).mockResolvedValueOnce({ status: 'not_found' }) })
    renderApp('/', api)
    await fillNewsletter()
    await waitFor(() => expect(api.queryNewsletterStatus).toHaveBeenCalledTimes(1), { timeout: 1500 })
    const email = screen.getByLabelText(/^Email Required/)
    const confirm = screen.getByLabelText(/Confirm email Required/)
    await userEvent.clear(email); await userEvent.type(email, 'new@example.com')
    await userEvent.clear(confirm); await userEvent.type(confirm, 'new@example.com')
    await waitFor(() => expect(api.queryNewsletterStatus).toHaveBeenCalledTimes(2), { timeout: 1500 })
    resolveOld({ status: 'matched', subscribed: true })
    await waitFor(() => expect(screen.getByText(/No existing newsletter preference/)).toBeInTheDocument())
    expect(screen.getByRole('checkbox')).not.toBeChecked()
  })

  it.each([
    [true, { result: 'set', subscribed: true }, /Authoritative preference: subscribed/],
    [false, { result: 'set', subscribed: false }, /Authoritative preference: not subscribed/],
    [false, { result: 'no_customer_no_change', subscribed: false }, /no new customer was created/],
  ])('saves final Boolean %s and displays authoritative state', async (checked, response, message) => {
    const api = client({ setNewsletterPreference: vi.fn().mockResolvedValue(response) })
    renderApp('/', api)
    const user = await fillNewsletter()
    if (checked) await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText(message)).toBeInTheDocument()
    expect(api.setNewsletterPreference.mock.calls[0][0].subscribed).toBe(checked)
  })

  it('replaces a matched subscribed OP-03 baseline with authoritative OP-04 unsubscribe', async () => {
    const api = client({ queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'matched', subscribed: true }), setNewsletterPreference: vi.fn().mockResolvedValue({ result: 'set', subscribed: false }) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await waitFor(() => expect(screen.getByRole('checkbox')).toBeChecked(), { timeout: 1500 })
    await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText('Current preference: not subscribed.')).toBeInTheDocument()
    expect(screen.queryByText('Current preference: subscribed.')).not.toBeInTheDocument()
  })

  it('replaces a not-found OP-03 baseline with authoritative OP-04 subscribe', async () => {
    const api = client({ queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'not_found' }), setNewsletterPreference: vi.fn().mockResolvedValue({ result: 'set', subscribed: true }) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await waitFor(() => expect(screen.getByText(/No existing newsletter preference/)).toBeInTheDocument(), { timeout: 1500 })
    await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText('Current preference: subscribed.')).toBeInTheDocument()
    expect(screen.queryByText(/No existing newsletter preference/)).not.toBeInTheDocument()
  })

  it('presents no-customer/no-change false as the sole authoritative current status', async () => {
    const api = client({ queryNewsletterStatus: vi.fn().mockResolvedValue({ status: 'not_found' }), setNewsletterPreference: vi.fn().mockResolvedValue({ result: 'no_customer_no_change', subscribed: false }) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await waitFor(() => expect(screen.getByText(/No existing newsletter preference/)).toBeInTheDocument(), { timeout: 1500 })
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByText('Current preference: not subscribed.')).toBeInTheDocument()
    expect(screen.queryByText(/No existing newsletter preference/)).not.toBeInTheDocument()
  })

  it('locks pending submission and suppresses duplicates', async () => {
    let resolveSave
    const api = client({ setNewsletterPreference: vi.fn().mockReturnValue(new Promise((resolve) => { resolveSave = resolve })) })
    renderApp('/', api)
    const user = await fillNewsletter()
    const button = screen.getByRole('button', { name: 'Save newsletter preference' })
    await user.click(button)
    expect(screen.getByRole('button', { name: /Saving preference/ })).toBeDisabled()
    expect(screen.getByLabelText(/First name Required/)).toBeDisabled()
    expect(api.setNewsletterPreference).toHaveBeenCalledTimes(1)
    resolveSave({ result: 'set', subscribed: false })
    expect(await screen.findByText(/Authoritative preference: not subscribed/)).toBeInTheDocument()
  })

  it('recovers outcome unknown with the identical immutable body', async () => {
    const api = client({ setNewsletterPreference: vi.fn().mockRejectedValueOnce(publicApiError('newsletter_preference_outcome_unknown', { retryable: true, outcomeUnknown: true })).mockResolvedValueOnce({ result: 'set', subscribed: true }) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByRole('heading', { name: 'Newsletter result not confirmed' })).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Resend the same preference' }))
    expect(await screen.findByText(/Authoritative preference: subscribed/)).toBeInTheDocument()
    expect(api.setNewsletterPreference.mock.calls[1][0]).toBe(api.setNewsletterPreference.mock.calls[0][0])
  })

  it.each(['customer_identity_conflict', 'middle_initial_conflict'])('maps %s without exposing stored values', async (code) => {
    const api = client({ setNewsletterPreference: vi.fn().mockRejectedValue(publicApiError(code, { status: 409 })) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    expect(await screen.findByRole('alert')).toHaveTextContent(/do not match|conflicts/)
    expect(document.body).not.toHaveTextContent(/stored email|customer ID/i)
  })

  it.each([
    ['newsletter_status_indeterminate', { retryable: true }, /could not check your newsletter status/i, true],
    ['service_unavailable', { retryable: true }, /temporarily unavailable/i, true],
    ['internal_error', { retryable: false }, /service response was invalid/i, false],
  ])('maps OP-03 %s without collapsing retry semantics', async (code, options, copy, hasRetry) => {
    const api = client({ queryNewsletterStatus: vi.fn().mockRejectedValue(publicApiError(code, options)) })
    renderApp('/', api)
    await fillNewsletter()
    expect(await screen.findByText(copy, {}, { timeout: 1500 })).toBeInTheDocument()
    expect(Boolean(screen.queryByRole('button', { name: 'Retry newsletter status' }))).toBe(hasRetry)
  })

  it('clears stale outcome-unknown recovery when resend returns a definitive identity conflict', async () => {
    const api = client({ setNewsletterPreference: vi.fn()
      .mockRejectedValueOnce(publicApiError('newsletter_preference_outcome_unknown', { retryable: true, outcomeUnknown: true }))
      .mockRejectedValueOnce(publicApiError('customer_identity_conflict', { status: 409 })) })
    renderApp('/', api)
    const user = await fillNewsletter()
    await user.click(screen.getByRole('checkbox'))
    await user.click(screen.getByRole('button', { name: 'Save newsletter preference' }))
    await user.click(await screen.findByRole('button', { name: 'Resend the same preference' }))
    expect(await screen.findByRole('alert')).toHaveFocus()
    expect(screen.queryByRole('button', { name: 'Resend the same preference' })).not.toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Save newsletter preference' })).toBeInTheDocument()
    expect(screen.getByLabelText(/First name Required/)).toBeEnabled()
  })

  it('does not apply native UTF-16 maxlength to code-point-limited name controls', () => {
    renderApp('/', client())
    expect(screen.getByLabelText(/First name Required/)).not.toHaveAttribute('maxlength')
    expect(screen.getByLabelText(/Middle initial Optional/)).not.toHaveAttribute('maxlength')
    expect(screen.getByLabelText(/Last name Required/)).not.toHaveAttribute('maxlength')
  })
})
