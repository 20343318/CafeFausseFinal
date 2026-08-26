import { Link } from 'react-router'
import heroImage from '../../assets/gallery/home-cafe-fausse.webp'
import interiorImage from '../../assets/gallery/gallery-cafe-interior.webp'
import ribeyeImage from '../../assets/gallery/gallery-ribeye-steak.webp'
import { AwardsSection, ReviewsSection } from '../components/AwardsAndReviews.jsx'
import { restaurant } from '../content/restaurant.js'
import { NewsletterPreferences } from '../features/newsletter/NewsletterPreferences.jsx'
import { CurrentHours } from '../features/hours/CurrentHours.jsx'

export function HomePage() {
  return (
    <>
      <section className="home-hero container">
        <div className="home-hero__content">
          <p className="eyebrow">Washington, DC</p>
          <h1 tabIndex="-1">Café Fausse</h1>
          <p className="home-hero__intro">
            Traditional Italian flavors meet modern culinary innovation in an unforgettable dining experience.
          </p>
          <div className="action-group">
            <Link className="button button--primary" to="/reservations">Reserve a table</Link>
            <Link className="button button--secondary" to="/menu">View the menu</Link>
          </div>
        </div>
        <img
          className="home-hero__image"
          src={heroImage}
          alt="Warmly lit formal dining room with chandeliers and set tables."
          width="1792"
          height="1024"
          decoding="async"
          fetchPriority="high"
        />
      </section>

      <section className="contact-strip" aria-labelledby="visit-heading">
        <div className="container contact-strip__grid">
          <div>
            <p className="eyebrow">Visit</p>
            <h2 id="visit-heading">Join us for dinner</h2>
          </div>
          <address>
            <strong>Address</strong><br />{restaurant.address}<br />
            <a href={restaurant.phoneHref}>{restaurant.phoneDisplay}</a>
          </address>
          <div>
            <strong>Hours</strong>
            <CurrentHours />
          </div>
        </div>
      </section>

      <section className="content-section container story-teaser" aria-labelledby="story-heading">
        <div className="story-teaser__copy">
          <p className="eyebrow">Our story</p>
          <h2 id="story-heading">Quality, creativity, and a memorable table</h2>
          <p>
            Founded in 2010 by Chef Antonio Rossi and restaurateur Maria Lopez, Café Fausse blends traditional Italian flavors with modern culinary innovation.
          </p>
          <p>
            Our mission is to provide an unforgettable dining experience reflecting quality and creativity, with excellent food and locally sourced ingredients.
          </p>
          <Link className="text-link" to="/about">Discover our story</Link>
        </div>
        <img
          src={interiorImage}
          alt="Formal dining room with chandeliers, floral arrangements, and round set tables."
          width="1792"
          height="1024"
          loading="lazy"
          decoding="async"
        />
      </section>

      <section className="content-section container home-feature" aria-labelledby="menu-feature-heading">
        <img
          src={ribeyeImage}
          alt="Grilled ribeye steak plated with vegetables and fresh herbs."
          width="1024"
          height="1024"
          loading="lazy"
          decoding="async"
        />
        <div>
          <p className="eyebrow">The menu</p>
          <h2 id="menu-feature-heading">Italian tradition, thoughtfully presented</h2>
          <p>Explore starters, main courses, desserts, wines, beer, and espresso.</p>
          <Link className="button button--secondary" to="/menu">Explore the full menu</Link>
        </div>
      </section>

      <div className="container home-recognition">
        <AwardsSection compact />
        <ReviewsSection compact />
      </div>

      <section id="newsletter" className="newsletter-section" aria-labelledby="newsletter-heading">
        <div className="container newsletter-section__inner">
          <div>
            <p className="eyebrow">Newsletter</p>
            <h2 id="newsletter-heading">Newsletter preferences</h2>
          </div>
          <p className="large-copy">
            This is the dedicated place to manage your Café Fausse newsletter preference.
          </p>
          <div data-feature-boundary="newsletter">
            <NewsletterPreferences />
          </div>
        </div>
      </section>
    </>
  )
}
