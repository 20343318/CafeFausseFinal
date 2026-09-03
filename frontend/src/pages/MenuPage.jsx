import ribeyeImage from '../../assets/gallery/gallery-ribeye-steak.webp'
import { menuCategories } from '../content/menu.js'

export function MenuPage() {
  return (
    <div className="page container">
      <div className="page-header reading-width">
        <p className="eyebrow">Dinner</p>
        <h1 tabIndex="-1">Menu</h1>
        <p className="large-copy">Four courses of familiar flavors and thoughtful details.</p>
      </div>
      <div className="menu-grid">
        {menuCategories.map((category) => (
          <section className="menu-section" aria-labelledby={`menu-${category.name.replaceAll(' ', '-').toLowerCase()}`} key={category.name}>
            <h2 id={`menu-${category.name.replaceAll(' ', '-').toLowerCase()}`}>{category.name}</h2>
            <dl className="menu-list">
              {category.items.map((item) => (
                <div className="menu-item" key={item.name}>
                  <dt>
                    <span>{item.name}</span>
                    <span className="menu-item__price">{item.price}</span>
                  </dt>
                  <dd>{item.description}</dd>
                </div>
              ))}
            </dl>
          </section>
        ))}
      </div>
      <figure className="menu-feature-image">
        <img
          className="menu-feature-image__image"
          src={ribeyeImage}
          alt="Grilled ribeye steak plated with vegetables and fresh herbs."
          width="1024"
          height="1024"
          loading="lazy"
          decoding="async"
        />
        <figcaption>Ribeye steak</figcaption>
      </figure>
    </div>
  )
}
