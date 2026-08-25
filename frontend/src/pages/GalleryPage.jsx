import { useCallback, useState } from 'react'
import { AwardsSection, ReviewsSection } from '../components/AwardsAndReviews.jsx'
import { GalleryGrid } from '../gallery/GalleryGrid.jsx'
import { GalleryLightbox } from '../gallery/GalleryLightbox.jsx'
import { galleryAssets } from '../gallery/gallery-discovery.js'

export function GalleryPage({ images = galleryAssets }) {
  const [selectedIndex, setSelectedIndex] = useState(null)
  const [opener, setOpener] = useState(null)

  const openLightbox = useCallback((index, trigger) => {
    setOpener(trigger)
    setSelectedIndex(index)
  }, [])

  const closeLightbox = useCallback(() => setSelectedIndex(null), [])

  return (
    <div className="page container gallery-page">
      <div className="page-header reading-width">
        <p className="eyebrow">Inside Café Fausse</p>
        <h1 tabIndex="-1">Gallery</h1>
        <p className="large-copy">Dining rooms, cuisine, special occasions, and work behind the scenes.</p>
      </div>

      <section aria-labelledby="gallery-grid-heading">
        <h2 id="gallery-grid-heading" className="visually-hidden">Café Fausse photographs</h2>
        <GalleryGrid images={images} onSelect={openLightbox} />
      </section>

      <GalleryLightbox
        images={images}
        selectedIndex={selectedIndex}
        opener={opener}
        onChange={setSelectedIndex}
        onClose={closeLightbox}
      />

      <AwardsSection />
      <ReviewsSection />
    </div>
  )
}
