export function GalleryGrid({ images, onSelect }) {
  return (
    <div className="gallery-grid">
      {images.map((image, index) => (
        <figure className="gallery-item" key={image.id}>
          <button
            className="gallery-item__button"
            type="button"
            onClick={(event) => onSelect(index, event.currentTarget)}
            aria-label={`Open enlarged image: ${image.alt}`}
          >
            <img
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              loading={index < 2 ? 'eager' : 'lazy'}
              decoding="async"
              style={{ objectPosition: image.objectPosition }}
              onError={(event) => {
                event.currentTarget.closest('.gallery-item')?.classList.add('has-image-error')
              }}
            />
            <span className="gallery-item__action" aria-hidden="true">View image</span>
          </button>
          {image.caption && <figcaption>{image.caption}</figcaption>}
        </figure>
      ))}
    </div>
  )
}
