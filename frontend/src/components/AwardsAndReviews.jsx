import { awards, reviews } from '../content/restaurant.js'

export function AwardsSection({ compact = false }) {
  return (
    <section className={compact ? 'content-section content-section--compact' : 'content-section'} aria-labelledby="awards-heading">
      <div className="section-heading">
        <p className="eyebrow">Recognition</p>
        <h2 id="awards-heading">Awards</h2>
      </div>
      <div className="award-grid">
        {awards.map((award) => (
          <article className="award-card" key={award.name}>
            <h3>{award.name}</h3>
            <p>{award.detail}</p>
          </article>
        ))}
      </div>
    </section>
  )
}

export function ReviewsSection({ compact = false }) {
  return (
    <section className={compact ? 'content-section content-section--compact' : 'content-section'} aria-labelledby="reviews-heading">
      <div className="section-heading">
        <p className="eyebrow">Guest perspective</p>
        <h2 id="reviews-heading">Reviews</h2>
      </div>
      <div className="review-grid">
        {reviews.map((review) => (
          <figure className="review-card" key={review.source}>
            <blockquote>“{review.quote}”</blockquote>
            <figcaption>— {review.source}</figcaption>
          </figure>
        ))}
      </div>
    </section>
  )
}
