export const reservationContextFixture = Object.freeze({
  restaurant: {
    address: '1234 Culinary Ave, Suite 100, Washington, DC 20002',
    phone: '(202) 555-4567',
  },
  restaurant_timezone: 'America/New_York',
  weekday_hours: [
    { iso_weekday: 1, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 2, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 3, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 4, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 5, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 6, opens_at_local: '17:00:00', closes_at_local: '23:00:00' },
    { iso_weekday: 7, opens_at_local: '17:00:00', closes_at_local: '21:00:00' },
  ],
  reservation_policy: {
    start_interval_minutes: 30,
    reservation_duration_minutes: 90,
    advance_window_days: 60,
    same_day_lead_minutes: 120,
  },
  reservable_date_range: {
    minimum_local_date: '2026-08-24',
    maximum_local_date: '2026-10-23',
  },
  maximum_party_size: 120,
})

export const availabilityFixture = Object.freeze({
  local_date: '2026-09-12',
  party_size: 4,
  restaurant_timezone: 'America/New_York',
  provisional: true,
  slots: [
    { starts_at_local: '2026-09-12T17:00:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T21:00:00Z', ends_at_local: '2026-09-12T18:30:00-04:00', ends_at: '2026-09-12T22:30:00Z', available: true },
    { starts_at_local: '2026-09-12T17:30:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T21:30:00Z', ends_at_local: '2026-09-12T19:00:00-04:00', ends_at: '2026-09-12T23:00:00Z', available: true },
    { starts_at_local: '2026-09-12T18:00:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T22:00:00Z', ends_at_local: '2026-09-12T19:30:00-04:00', ends_at: '2026-09-12T23:30:00Z', available: false },
    { starts_at_local: '2026-09-12T18:30:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T22:30:00Z', ends_at_local: '2026-09-12T20:00:00-04:00', ends_at: '2026-09-13T00:00:00Z', available: false },
    { starts_at_local: '2026-09-12T19:00:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T23:00:00Z', ends_at_local: '2026-09-12T20:30:00-04:00', ends_at: '2026-09-13T00:30:00Z', available: true },
    { starts_at_local: '2026-09-12T19:30:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-12T23:30:00Z', ends_at_local: '2026-09-12T21:00:00-04:00', ends_at: '2026-09-13T01:00:00Z', available: true },
    { starts_at_local: '2026-09-12T20:00:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-13T00:00:00Z', ends_at_local: '2026-09-12T21:30:00-04:00', ends_at: '2026-09-13T01:30:00Z', available: true },
    { starts_at_local: '2026-09-12T20:30:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-13T00:30:00Z', ends_at_local: '2026-09-12T22:00:00-04:00', ends_at: '2026-09-13T02:00:00Z', available: false },
    { starts_at_local: '2026-09-12T21:00:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-13T01:00:00Z', ends_at_local: '2026-09-12T22:30:00-04:00', ends_at: '2026-09-13T02:30:00Z', available: true },
    { starts_at_local: '2026-09-12T21:30:00-04:00', utc_offset_minutes: -240, starts_at: '2026-09-13T01:30:00Z', ends_at_local: '2026-09-12T23:00:00-04:00', ends_at: '2026-09-13T03:00:00Z', available: true },
  ],
})

export const confirmationFixture = Object.freeze({
  booking_result: 'created',
  confirmation: {
    reservation_reference: '9007199254740993',
    customer_name: 'Ada M. Rivera',
    starts_at_local: '2026-09-12T17:00:00-04:00',
    ends_at_local: '2026-09-12T18:30:00-04:00',
    starts_at: '2026-09-12T21:00:00Z',
    ends_at: '2026-09-12T22:30:00Z',
    party_size: 4,
    assigned_table_numbers: [7],
    newsletter_subscribed: true,
    restaurant: reservationContextFixture.restaurant,
  },
})

export const knownCustomerFixture = Object.freeze({
  first_name: 'Ada',
  middle_initial: 'M',
  last_name: 'Rivera',
  email: 'ada.rivera@example.com',
  subscribed: true,
})

export const newCustomerFixture = Object.freeze({
  first_name: 'Lin',
  last_name: 'Okafor',
  email: 'lin.okafor@example.com',
})

export function cloneFixture(value) {
  return structuredClone(value)
}

export function publicApiError(code, { retryable = false, outcomeUnknown = false, fields, status = 503 } = {}) {
  const error = new Error(code)
  error.status = status
  error.response = {
    error: {
      code,
      message: 'The requested operation could not be completed.',
      retryable,
      outcome_unknown: outcomeUnknown,
      ...(fields ? { fields } : {}),
    },
  }
  return error
}

function normalizedName(value) {
  return value.trim().replace(/\s+/gu, ' ').toLocaleLowerCase()
}

function normalizedEmail(value) {
  return value.trim().toLowerCase()
}

function classifyIdentity(body) {
  if (normalizedEmail(body.email) !== knownCustomerFixture.email) return 'unknown'
  if (normalizedName(body.first_name) !== normalizedName(knownCustomerFixture.first_name)
    || normalizedName(body.last_name) !== normalizedName(knownCustomerFixture.last_name)) return 'identity_conflict'
  if (body.middle_initial && body.middle_initial.trim().replace(/\.$/u, '').toUpperCase() !== knownCustomerFixture.middle_initial) return 'middle_conflict'
  return 'known'
}

function throwIdentityConflict(classification) {
  if (classification === 'identity_conflict') throw publicApiError('customer_identity_conflict', { status: 409 })
  if (classification === 'middle_conflict') throw publicApiError('middle_initial_conflict', { status: 409 })
}

export function resolveAvailability({ local_date, party_size }) {
  if (local_date === availabilityFixture.local_date && party_size === availabilityFixture.party_size) return cloneFixture(availabilityFixture)
  return {
    local_date,
    party_size,
    restaurant_timezone: reservationContextFixture.restaurant_timezone,
    provisional: true,
    slots: [],
  }
}

export function resolveNewsletterStatus(body) {
  const classification = classifyIdentity(body)
  throwIdentityConflict(classification)
  return classification === 'known'
    ? { status: 'matched', subscribed: knownCustomerFixture.subscribed }
    : { status: 'not_found' }
}

export function resolveNewsletterPreference(body) {
  const classification = classifyIdentity(body)
  throwIdentityConflict(classification)
  if (classification === 'unknown' && body.subscribed === false) return { result: 'no_customer_no_change', subscribed: false }
  return { result: 'set', subscribed: body.subscribed }
}

export function resolveReservation(body) {
  const classification = classifyIdentity(body)
  throwIdentityConflict(classification)
  const slot = availabilityFixture.slots.find((candidate) => candidate.starts_at_local === body.starts_at_local)
  const isKnown = classification === 'known'
  const isApprovedNewFixture = normalizedEmail(body.email) === newCustomerFixture.email
    && normalizedName(body.first_name) === normalizedName(newCustomerFixture.first_name)
    && normalizedName(body.last_name) === normalizedName(newCustomerFixture.last_name)
    && !body.middle_initial
  if (!slot || body.party_size !== availabilityFixture.party_size || (!isKnown && !isApprovedNewFixture)) {
    throw publicApiError('internal_error', { status: 500 })
  }
  const result = cloneFixture(confirmationFixture)
  result.confirmation.customer_name = isKnown ? 'Ada M. Rivera' : 'Lin Okafor'
  result.confirmation.starts_at_local = slot.starts_at_local
  result.confirmation.ends_at_local = slot.ends_at_local
  result.confirmation.starts_at = slot.starts_at
  result.confirmation.ends_at = slot.ends_at
  result.confirmation.party_size = availabilityFixture.party_size
  result.confirmation.newsletter_subscribed = body.newsletter_action === 'subscribe'
    ? true
    : body.newsletter_action === 'unsubscribe'
      ? false
      : isKnown ? knownCustomerFixture.subscribed : false
  return result
}
