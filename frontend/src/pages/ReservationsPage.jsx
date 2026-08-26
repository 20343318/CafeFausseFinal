import { restaurant } from '../content/restaurant.js'
import { ReservationFeatureBoundary } from '../features/reservations/ReservationFeature.jsx'

export function ReservationsPage() {
  return (
    <div className="page container reservation-page">
      <div className="page-header reading-width">
        <p className="eyebrow">Your table</p>
        <h1 tabIndex="-1">Reservations</h1>
        <p className="large-copy">
          Plan your visit around Café Fausse dining hours and available reservation times.
        </p>
      </div>
      <section className="reservation-intro" aria-labelledby="reservation-info-heading">
        <div>
          <h2 id="reservation-info-heading">Dining information</h2>
          <p>{restaurant.address}</p>
          <p><a href={restaurant.phoneHref}>{restaurant.phoneDisplay}</a></p>
        </div>
        <div>
          <h3>Current hours and policies</h3>
          <p>Live dining hours, date limits, and reservation policies load below.</p>
        </div>
      </section>
      <section className="reservation-feature-boundary" aria-label="Reservation controls" data-feature-boundary="reservation">
        <ReservationFeatureBoundary />
      </section>
    </div>
  )
}
