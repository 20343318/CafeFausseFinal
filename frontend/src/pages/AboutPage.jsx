import { Link } from 'react-router'
import interiorImage from '../../assets/gallery/gallery-cafe-interior.webp'

export function AboutPage() {
  return (
    <div className="page">
      <div className="page-header container reading-width">
        <p className="eyebrow">Since 2010</p>
        <h1 tabIndex="-1">About Us</h1>
        <p className="large-copy">A restaurant founded around quality, creativity, and unforgettable dining.</p>
      </div>
      <section className="container about-story" aria-labelledby="about-story-heading">
        <div>
          <h2 id="about-story-heading">Our story</h2>
          <p>
            Café Fausse was founded in 2010 by Chef Antonio Rossi and restaurateur Maria Lopez. It blends traditional Italian flavors with modern culinary innovation.
          </p>
          <p>
            Its mission is to provide an unforgettable dining experience reflecting quality and creativity.
          </p>
        </div>
        <img
          src={interiorImage}
          alt="Formal dining room with chandeliers, floral arrangements, and round set tables."
          width="1792"
          height="1024"
          decoding="async"
        />
      </section>
      <section className="founders-section" aria-labelledby="founders-heading">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">The founders</p>
            <h2 id="founders-heading">Meet our co-founders</h2>
          </div>
          <div className="founder-grid">
            <article className="founder-card">
              <h3>Chef Antonio Rossi</h3>
              <p>
                Chef Antonio Rossi co-founded Café Fausse in 2010 with restaurateur Maria Lopez. At Café Fausse, he is part of a restaurant founded around the combination of traditional Italian flavors and modern culinary innovation, with a commitment to excellent food and an unforgettable dining experience.
              </p>
            </article>
            <article className="founder-card">
              <h3>Maria Lopez</h3>
              <p>
                Restaurateur Maria Lopez co-founded Café Fausse in 2010 with Chef Antonio Rossi. At Café Fausse, she is part of a restaurant committed to quality, creativity, locally sourced ingredients, and providing guests with an unforgettable dining experience.
              </p>
            </article>
          </div>
        </div>
      </section>
      <section className="content-section container commitments" aria-labelledby="commitments-heading">
        <div>
          <p className="eyebrow">Our commitment</p>
          <h2 id="commitments-heading">What guides us</h2>
        </div>
        <ul>
          <li>Unforgettable dining</li>
          <li>Excellent food</li>
          <li>Locally sourced ingredients</li>
          <li>Quality</li>
          <li>Creativity</li>
        </ul>
        <Link className="button button--primary" to="/reservations">Reserve a table</Link>
      </section>
    </div>
  )
}
