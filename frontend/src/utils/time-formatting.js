export function formatClockTime(value) {
  const match = String(value).match(/(?:^|T)(\d{2}):(\d{2})(?::|$)/)
  if (!match) return value

  const hour = Number(match[1])
  const minute = Number(match[2])
  if (hour > 23 || minute > 59) return value

  return `${hour % 12 || 12}:${match[2]} ${hour >= 12 ? 'PM' : 'AM'}`
}

export function formatRestaurantDateTime(utcTimestamp, restaurantTimezone) {
  if (!restaurantTimezone) throw new Error('A restaurant timezone is required to format a reservation time.')

  const instant = new Date(utcTimestamp)
  if (Number.isNaN(instant.getTime())) return utcTimestamp

  return new Intl.DateTimeFormat('en-US', {
    timeZone: restaurantTimezone,
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
    timeZoneName: 'longGeneric',
  }).format(instant)
}
