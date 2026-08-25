import { useEffect, useId, useRef, useState } from 'react'
import { createPortal } from 'react-dom'

function getFocusableElements(container) {
  return Array.from(
    container.querySelectorAll(
      'button:not([disabled]), a[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
    ),
  )
}

export function GalleryLightbox({ images, selectedIndex, opener, onChange, onClose }) {
  const closeRef = useRef(null)
  const dialogRef = useRef(null)
  const titleId = useId()
  const descriptionId = useId()
  const [imageFailed, setImageFailed] = useState(false)
  const image = selectedIndex === null ? null : images[selectedIndex]
  const isOpen = Boolean(image)

  useEffect(() => {
    setImageFailed(false)
  }, [selectedIndex])

  useEffect(() => {
    if (!isOpen) return undefined

    const background = document.querySelector('[data-app-shell]')
    const previousOverflow = document.body.style.overflow
    const previousPaddingRight = document.body.style.paddingRight
    const previousAriaHidden = background?.getAttribute('aria-hidden')
    const scrollbarWidth = Math.max(0, window.innerWidth - document.documentElement.clientWidth)

    background?.setAttribute('inert', '')
    background?.setAttribute('aria-hidden', 'true')
    document.body.style.overflow = 'hidden'
    if (scrollbarWidth > 0) document.body.style.paddingRight = `${scrollbarWidth}px`
    closeRef.current?.focus()

    return () => {
      background?.removeAttribute('inert')
      if (previousAriaHidden === null || previousAriaHidden === undefined) {
        background?.removeAttribute('aria-hidden')
      } else {
        background?.setAttribute('aria-hidden', previousAriaHidden)
      }
      document.body.style.overflow = previousOverflow
      document.body.style.paddingRight = previousPaddingRight
      opener?.focus()
    }
  }, [isOpen, opener])

  useEffect(() => {
    if (!image) return undefined

    function onKeyDown(event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        onClose()
        return
      }
      if (event.key === 'ArrowLeft' && selectedIndex > 0) {
        event.preventDefault()
        onChange(selectedIndex - 1)
        return
      }
      if (event.key === 'ArrowRight' && selectedIndex < images.length - 1) {
        event.preventDefault()
        onChange(selectedIndex + 1)
        return
      }
      if (event.key !== 'Tab') return

      const focusable = getFocusableElements(dialogRef.current)
      if (focusable.length === 0) {
        event.preventDefault()
        return
      }
      const first = focusable[0]
      const last = focusable.at(-1)
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', onKeyDown)
    return () => document.removeEventListener('keydown', onKeyDown)
  }, [image, images.length, onChange, onClose, selectedIndex])

  if (!image) return null

  return createPortal(
    <div className="lightbox-backdrop" data-testid="lightbox-backdrop">
      <div
        ref={dialogRef}
        className="gallery-lightbox"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descriptionId}
      >
        <h2 id={titleId} className="visually-hidden">Enlarged Gallery image</h2>
        <button ref={closeRef} className="lightbox-control lightbox-close" type="button" onClick={onClose}>
          <span aria-hidden="true">×</span>
          <span>Close</span>
        </button>

        <div className="lightbox-media">
          {imageFailed ? (
            <p className="lightbox-image-error" role="status">This image could not be displayed.</p>
          ) : (
            <img
              src={image.src}
              alt={image.alt}
              width={image.width}
              height={image.height}
              decoding="async"
              onError={() => setImageFailed(true)}
            />
          )}
        </div>

        <div className="lightbox-details">
          <p id={descriptionId}>{image.caption || image.alt}</p>
          <p aria-live="polite">{selectedIndex + 1} of {images.length}</p>
        </div>

        {images.length > 1 && (
          <div className="lightbox-navigation" aria-label="Gallery image navigation">
            <button
              className="lightbox-control"
              type="button"
              disabled={selectedIndex === 0}
              onClick={() => onChange(selectedIndex - 1)}
            >
              <span aria-hidden="true">←</span> Previous
            </button>
            <button
              className="lightbox-control"
              type="button"
              disabled={selectedIndex === images.length - 1}
              onClick={() => onChange(selectedIndex + 1)}
            >
              Next <span aria-hidden="true">→</span>
            </button>
          </div>
        )}
      </div>
    </div>,
    document.body,
  )
}
