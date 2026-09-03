import { describe, expect, it } from 'vitest'
import { formatClockTime, formatRestaurantDateTime } from '../utils/time-formatting.js'

describe('customer-facing time formatting', () => {
  it('formats operating-hour and reservation-slot clock values with AM/PM', () => {
    expect(formatClockTime('17:00:00')).toBe('5:00 PM')
    expect(formatClockTime('2026-09-12T18:30:00-04:00')).toBe('6:30 PM')
    expect(formatClockTime('00:00:00')).toBe('12:00 AM')
    expect(formatClockTime('12:00:00')).toBe('12:00 PM')
  })

  it('converts a canonical UTC confirmation time to the configured restaurant timezone', () => {
    expect(formatRestaurantDateTime('2026-09-03T17:00:00Z', 'America/New_York'))
      .toBe('September 3, 2026 at 1:00 PM Eastern Time')
    expect(formatRestaurantDateTime('2026-09-03T17:00:00Z', 'America/Los_Angeles'))
      .toBe('September 3, 2026 at 10:00 AM Pacific Time')
  })

  it('applies the restaurant timezone across the spring daylight-saving transition', () => {
    expect(formatRestaurantDateTime('2026-03-08T06:30:00Z', 'America/New_York'))
      .toBe('March 8, 2026 at 1:30 AM Eastern Time')
    expect(formatRestaurantDateTime('2026-03-08T07:30:00Z', 'America/New_York'))
      .toBe('March 8, 2026 at 3:30 AM Eastern Time')
  })
})
