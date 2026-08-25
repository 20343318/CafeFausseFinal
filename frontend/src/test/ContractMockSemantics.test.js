import { describe, expect, it } from 'vitest'
import {
  availabilityFixture,
  resolveAvailability,
  resolveNewsletterPreference,
  resolveNewsletterStatus,
  resolveReservation,
} from '../api/contractFixtures.js'

const ada = {
  first_name: 'Ada',
  middle_initial: 'M.',
  last_name: 'Rivera',
  email: 'ada.rivera@example.com',
  confirmation_email: 'ada.rivera@example.com',
}

describe('contract-faithful default fixture resolvers', () => {
  it('limits the complete OP-02 example schedule to its exact date and party key', () => {
    expect(resolveAvailability({ local_date: '2026-09-12', party_size: 4 }).slots).toHaveLength(10)
    expect(resolveAvailability({ local_date: '2026-09-12', party_size: 5 })).toMatchObject({ local_date: '2026-09-12', party_size: 5, provisional: true, slots: [] })
    expect(resolveAvailability({ local_date: '2026-09-13', party_size: 4 })).toMatchObject({ local_date: '2026-09-13', party_size: 4, provisional: true, slots: [] })
  })

  it('uses full permitted OP-03 identity semantics, including omitted middle initial', () => {
    expect(resolveNewsletterStatus(ada)).toEqual({ status: 'matched', subscribed: true })
    expect(resolveNewsletterStatus({ ...ada, middle_initial: undefined })).toEqual({ status: 'matched', subscribed: true })
    expect(() => resolveNewsletterStatus({ ...ada, first_name: 'Grace' })).toThrowError(expect.objectContaining({ response: { error: expect.objectContaining({ code: 'customer_identity_conflict' }) } }))
    expect(() => resolveNewsletterStatus({ ...ada, middle_initial: 'Q' })).toThrowError(expect.objectContaining({ response: { error: expect.objectContaining({ code: 'middle_initial_conflict' }) } }))
    expect(resolveNewsletterStatus({ ...ada, first_name: 'Lin', last_name: 'Okafor', email: 'lin.okafor@example.com' })).toEqual({ status: 'not_found' })
  })

  it('returns every authoritative OP-04 final-state outcome', () => {
    expect(resolveNewsletterPreference({ ...ada, subscribed: true })).toEqual({ result: 'set', subscribed: true })
    expect(resolveNewsletterPreference({ ...ada, subscribed: false })).toEqual({ result: 'set', subscribed: false })
    expect(resolveNewsletterPreference({ ...ada, email: 'lin.okafor@example.com', first_name: 'Lin', last_name: 'Okafor', subscribed: true })).toEqual({ result: 'set', subscribed: true })
    expect(resolveNewsletterPreference({ ...ada, email: 'lin.okafor@example.com', first_name: 'Lin', last_name: 'Okafor', subscribed: false })).toEqual({ result: 'no_customer_no_change', subscribed: false })
  })

  it('uses server fixture facts for OP-05 stored spelling, interval, and newsletter state', () => {
    const request = { ...ada, starts_at_local: availabilityFixture.slots[0].starts_at_local, utc_offset_minutes: -240, party_size: 4, newsletter_action: 'no_change' }
    const unchanged = resolveReservation(request).confirmation
    expect(unchanged).toMatchObject({ customer_name: 'Ada M. Rivera', newsletter_subscribed: true, starts_at_local: availabilityFixture.slots[0].starts_at_local, ends_at_local: availabilityFixture.slots[0].ends_at_local, starts_at: availabilityFixture.slots[0].starts_at, ends_at: availabilityFixture.slots[0].ends_at })
    expect(resolveReservation({ ...request, first_name: 'ADA', middle_initial: undefined }).confirmation.customer_name).toBe('Ada M. Rivera')
    expect(resolveReservation({ ...request, newsletter_action: 'unsubscribe' }).confirmation.newsletter_subscribed).toBe(false)
    expect(resolveReservation({ ...request, newsletter_action: 'subscribe' }).confirmation.newsletter_subscribed).toBe(true)
  })
})
