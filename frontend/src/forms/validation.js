const EMAIL_LOCAL = /^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*$/
const DOMAIN_LABEL = /^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$/
const FIELD_ORDER = ['first_name', 'middle_initial', 'last_name', 'email', 'confirmation_email', 'phone', 'local_date', 'party_size', 'starts_at_local', 'utc_offset_minutes']

export function normalizeEmail(value) {
  return value.trim().toLowerCase()
}

export function normalizeName(value) {
  return value.trim().replace(/\s+/gu, ' ')
}

export function isValidEmail(value) {
  const email = value.trim()
  if (!email || email.length > 254 || /\s/.test(email)) return false
  const pieces = email.split('@')
  if (pieces.length !== 2 || !EMAIL_LOCAL.test(pieces[0])) return false
  const labels = pieces[1].split('.')
  return labels.every((label) => label.length <= 63 && DOMAIN_LABEL.test(label))
}

export function validateIdentity(values, { includePhone = false } = {}) {
  const errors = {}
  for (const field of ['first_name', 'last_name']) {
    const normalized = normalizeName(values[field] || '')
    if (!normalized) errors[field] = 'This field is required.'
    else if ([...normalized].length > 100 || !/\p{L}/u.test(normalized)) errors[field] = 'Enter a name containing a letter, up to 100 characters.'
  }
  const middle = (values.middle_initial || '').trim()
  if (middle && !/^\p{L}$/u.test(middle)) errors.middle_initial = 'Enter one letter.'
  if (!values.email?.trim()) errors.email = 'Email is required.'
  else if (!isValidEmail(values.email)) errors.email = 'Enter a valid email address.'
  if (!values.confirmation_email?.trim()) errors.confirmation_email = 'Confirm email is required.'
  else if (!isValidEmail(values.confirmation_email)) errors.confirmation_email = 'Enter a valid email address.'
  else if (isValidEmail(values.email || '') && normalizeEmail(values.email) !== normalizeEmail(values.confirmation_email)) errors.confirmation_email = 'Email addresses must match.'
  if (includePhone && values.phone) {
    const phone = values.phone.trim()
    const digits = phone.replace(/\D/g, '')
    if (phone.length > 32 || !/^[0-9 +().-]+$/.test(phone) || digits.length < 7 || digits.length > 15) errors.phone = 'Enter a phone number containing 7 to 15 digits.'
  }
  return errors
}

export function identityIsEligible(values) {
  return Object.keys(validateIdentity(values)).length === 0
}

export function identityBody(values) {
  return {
    first_name: normalizeName(values.first_name),
    ...(values.middle_initial?.trim() ? { middle_initial: values.middle_initial.trim() } : {}),
    last_name: normalizeName(values.last_name),
    email: normalizeEmail(values.email),
    confirmation_email: normalizeEmail(values.confirmation_email),
  }
}

export function sortErrors(errors) {
  return Object.entries(errors).sort(([left], [right]) => FIELD_ORDER.indexOf(left) - FIELD_ORDER.indexOf(right))
}

export const fieldLabels = {
  first_name: 'First name', middle_initial: 'Middle initial', last_name: 'Last name', email: 'Email', confirmation_email: 'Confirm email', phone: 'Phone', local_date: 'Reservation date', party_size: 'Party size', starts_at_local: 'Reservation time', utc_offset_minutes: 'Reservation time',
}
