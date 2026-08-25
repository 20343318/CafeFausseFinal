async function read(response) {
  const body = await response.json()
  if (!response.ok) {
    const error = new Error(body.error?.code || 'request_failed')
    error.status = response.status
    error.response = body
    throw error
  }
  return body
}

// Test-only adapter. Prompt 24 owns the production/native-fetch Flask adapter.
export const mswOperationClient = {
  getReservationContext: () => fetch('/api/v1/reservation-context').then(read),
  getReservationAvailability: ({ local_date, party_size }) => fetch(`/api/v1/reservation-availability?local_date=${encodeURIComponent(local_date)}&party_size=${party_size}`).then(read),
  queryNewsletterStatus: (body) => fetch('/api/v1/newsletter-status-queries', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).then(read),
  setNewsletterPreference: (body) => fetch('/api/v1/newsletter-preferences', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).then(read),
  createReservation: (body) => fetch('/api/v1/reservations', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).then(read),
}
