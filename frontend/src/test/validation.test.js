import { describe, expect, it } from 'vitest'
import { identityBody, isValidEmail, normalizeEmail, normalizeName, validateIdentity } from '../forms/validation.js'

describe('contract-compatible client validation', () => {
  it('normalizes only approved name whitespace and email casing', () => {
    expect(normalizeName('  Ada   María  ')).toBe('Ada María')
    expect(normalizeEmail(' ADA.Rivera@Example.COM ')).toBe('ada.rivera@example.com')
  })

  it.each(['ada@example.com', "o'hara+table@example.co.uk", 'a_b@example.org'])('accepts the ordinary email profile: %s', (email) => {
    expect(isValidEmail(email)).toBe(true)
  })

  it('accepts a valid single-label email domain', () => {
    expect(isValidEmail('ada@localhost')).toBe(true)
  })

  it.each(['ada', '.ada@example.com', 'ada..rivera@example.com', 'ada@-example.com', 'Ada <ada@example.com>'])('rejects unsupported email syntax: %s', (email) => {
    expect(isValidEmail(email)).toBe(false)
  })

  it('requires matching normalized confirmation email', () => {
    const errors = validateIdentity({ first_name: 'Ada', last_name: 'Rivera', middle_initial: '', email: 'ada@example.com', confirmation_email: 'other@example.com' })
    expect(errors.confirmation_email).toBe('Email addresses must match.')
  })

  it('keeps middle initial and phone optional but validates supplied values', () => {
    const base = { first_name: 'Ada', last_name: 'Rivera', email: 'ada@example.com', confirmation_email: 'ada@example.com' }
    expect(validateIdentity(base, { includePhone: true })).toEqual({})
    expect(validateIdentity({ ...base, middle_initial: 'MM', phone: '12' }, { includePhone: true })).toMatchObject({ middle_initial: expect.any(String), phone: expect.any(String) })
  })

  it('counts name limits in Unicode code points and accepts supplementary-plane letters', () => {
    const supplementaryLetter = '\u{10400}'
    const base = { last_name: 'Rivera', middle_initial: '', email: 'ada@localhost', confirmation_email: 'ada@localhost' }
    expect(validateIdentity({ ...base, first_name: supplementaryLetter })).toEqual({})
    expect(validateIdentity({ ...base, first_name: supplementaryLetter.repeat(100) })).toEqual({})
    expect(validateIdentity({ ...base, first_name: supplementaryLetter.repeat(101) })).toHaveProperty('first_name')
  })

  it('accepts a supplementary-plane middle initial with or without a period', () => {
    const base = { first_name: 'Ada', last_name: 'Rivera', email: 'ada@localhost', confirmation_email: 'ada@localhost' }
    expect(validateIdentity({ ...base, middle_initial: '\u{10400}' })).toEqual({})
    expect(validateIdentity({ ...base, middle_initial: '\u{10400}.' })).toEqual({})
  })

  it('omits optional fields from the exact identity body', () => {
    expect(identityBody({ first_name: ' Ada ', middle_initial: '', last_name: ' Rivera ', email: 'ADA@EXAMPLE.COM', confirmation_email: 'ada@example.com' })).toEqual({ first_name: 'Ada', last_name: 'Rivera', email: 'ada@example.com', confirmation_email: 'ada@example.com' })
  })
})
