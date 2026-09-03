import { describe, expect, it } from 'vitest'
import { galleryMetadata } from '../content/gallery-metadata.js'
import {
  createGalleryAssets,
  deriveAltFromFilename,
  findOrphanMetadata,
  galleryAssets,
  isSupportedGalleryFile,
  orphanGalleryMetadata,
} from '../gallery/gallery-discovery.js'

describe('Gallery automatic discovery', () => {
  it('includes every current supported source asset without orphan metadata', () => {
    expect(galleryAssets.map((asset) => asset.filename)).toEqual([
      'home-cafe-fausse.webp',
      'gallery-cafe-interior.webp',
      'gallery-ribeye-steak.webp',
      'gallery-special-event.webp',
      'gallery-behind-the-scenes.webp',
    ])
    expect(galleryAssets).toHaveLength(5)
    expect(orphanGalleryMetadata).toEqual([])
    expect(galleryAssets.map((asset) => asset.caption)).toEqual([
      'Café Fausse dining room',
      'Formal dining room',
      'Ribeye steak',
      'Special event',
      'Behind the scenes',
    ])
    expect(galleryAssets.find((asset) => asset.filename === 'gallery-behind-the-scenes.webp')).toMatchObject({
      alt: 'Chefs plating dishes in a warmly lit professional kitchen.',
      src: expect.stringContaining('gallery-behind-the-scenes'),
    })
  })

  it.each([
    'one.webp', 'one.WEBP', 'one.WeBp',
    'one.jpg', 'one.JPG', 'one.JpG',
    'one.jpeg', 'one.JPEG', 'one.JpEg',
    'one.png', 'one.PNG', 'one.PnG',
    'one.avif', 'one.AVIF', 'one.AvIf',
  ])('accepts the supported case-insensitive extension in %s', (filename) => {
    expect(isSupportedGalleryFile(`/gallery/${filename}`)).toBe(true)
  })

  it.each(['one.gif', 'one.svg', 'one.txt', 'one.webp.svg'])('excludes unsupported input %s', (filename) => {
    expect(isSupportedGalleryFile(`/gallery/${filename}`)).toBe(false)
  })

  it('adds a synthetic supported file without a registry or metadata change', () => {
    const assets = createGalleryAssets({
      '../../assets/gallery/home-cafe-fausse.webp': '/home.webp',
      '../../assets/gallery/future-patio.JpG': '/future.jpg',
    }, {
      'home-cafe-fausse.webp': galleryMetadata['home-cafe-fausse.webp'],
    })
    expect(assets.map((asset) => asset.filename)).toEqual(['home-cafe-fausse.webp', 'future-patio.JpG'])
    expect(assets[1]).toMatchObject({
      alt: 'Future patio',
      caption: 'Future patio',
      hasMetadata: false,
    })
  })

  it('derives fact-limited readable fallback alt text', () => {
    expect(deriveAltFromFilename('private---dining_room  view.avif')).toBe('Private dining room view')
    expect(deriveAltFromFilename('.webp')).toBe('Gallery image')
  })

  it('sorts metadata-backed images before no-metadata using the complete frozen algorithm', () => {
    const input = {
      '/gallery/z-last.png': '/z',
      '/gallery/Beta.jpg': '/beta-upper',
      '/gallery/beta.JPG': '/beta-lower',
      '/gallery/m-unordered.webp': '/m',
      '/gallery/a-unordered.webp': '/a',
      '/gallery/no-meta-b.avif': '/b',
      '/gallery/no-meta-a.jpeg': '/a-no-meta',
    }
    const metadata = {
      'z-last.png': { alt: 'Z', order: 2 },
      'Beta.jpg': { alt: 'Beta upper', order: 1 },
      'beta.JPG': { alt: 'Beta lower', order: 1 },
      'm-unordered.webp': { alt: 'M' },
      'a-unordered.webp': { alt: 'A' },
    }

    expect(() => createGalleryAssets(input, metadata)).toThrow(/Duplicate normalized Gallery filename: Beta.jpg, beta.JPG/)

    delete input['/gallery/beta.JPG']
    delete metadata['beta.JPG']
    const expected = [
      'Beta.jpg',
      'z-last.png',
      'a-unordered.webp',
      'm-unordered.webp',
      'no-meta-a.jpeg',
      'no-meta-b.avif',
    ]
    expect(createGalleryAssets(input, metadata).map((asset) => asset.filename)).toEqual(expected)
    expect(createGalleryAssets(Object.fromEntries(Object.entries(input).reverse()), metadata).map((asset) => asset.filename)).toEqual(expected)
  })

  it('uses exact filename as the duplicate-order tie-breaker when normalized names differ only after normalization is avoided', () => {
    const assets = createGalleryAssets({
      '/gallery/bravo.jpg': '/bravo',
      '/gallery/Alpha.jpg': '/alpha',
      '/gallery/charlie.jpg': '/charlie',
    }, {
      'bravo.jpg': { alt: 'Bravo', order: 4 },
      'Alpha.jpg': { alt: 'Alpha', order: 4 },
      'charlie.jpg': { alt: 'Charlie', order: 4 },
    })
    expect(assets.map((asset) => asset.filename)).toEqual(['Alpha.jpg', 'bravo.jpg', 'charlie.jpg'])
  })

  it('diagnoses stale metadata separately from inclusion', () => {
    expect(findOrphanMetadata({
      'known.webp': { alt: 'Known' },
      'stale.png': { alt: 'Stale' },
    }, ['/gallery/known.webp'])).toEqual(['stale.png'])
  })
})
