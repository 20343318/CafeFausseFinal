import { galleryMetadata } from '../content/gallery-metadata.js'

export const supportedGalleryExtensions = ['webp', 'jpg', 'jpeg', 'png', 'avif']

const discoveredModules = import.meta.glob(
  '../../assets/gallery/*.{webp,jpg,jpeg,png,avif}',
  {
    eager: true,
    query: '?url',
    import: 'default',
    caseSensitive: false,
  },
)

function compareStrings(left, right) {
  if (left < right) return -1
  if (left > right) return 1
  return 0
}

export function filenameFromPath(path) {
  return path.split(/[\\/]/).at(-1)
}

export function normalizeFilename(filename) {
  return filename.normalize('NFKC').toLocaleLowerCase('en-US')
}

export function isSupportedGalleryFile(path) {
  const extension = filenameFromPath(path).split('.').at(-1)?.toLocaleLowerCase('en-US')
  return supportedGalleryExtensions.includes(extension)
}

export function deriveAltFromFilename(filename) {
  const withoutExtension = filename.replace(/\.[^.]+$/, '')
  const readable = withoutExtension
    .replace(/[-_\s]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ')

  if (!readable) return 'Gallery image'
  return `${readable.charAt(0).toLocaleUpperCase('en-US')}${readable.slice(1)}`
}

export function findOrphanMetadata(metadata, discoveredPaths) {
  const filenames = new Set(discoveredPaths.map(filenameFromPath))
  return Object.keys(metadata)
    .filter((filename) => !filenames.has(filename))
    .sort(compareStrings)
}

function compareAssets(left, right) {
  if (left.hasMetadata !== right.hasMetadata) return left.hasMetadata ? -1 : 1

  if (left.hasMetadata && right.hasMetadata) {
    const leftOrdered = Number.isFinite(left.order)
    const rightOrdered = Number.isFinite(right.order)
    if (leftOrdered !== rightOrdered) return leftOrdered ? -1 : 1
    if (leftOrdered && left.order !== right.order) return left.order - right.order
  }

  return (
    compareStrings(left.normalizedFilename, right.normalizedFilename)
    || compareStrings(left.filename, right.filename)
  )
}

export function createGalleryAssets(globResult, metadata = galleryMetadata) {
  const entries = Object.entries(globResult)
    .filter(([path]) => isSupportedGalleryFile(path))
    .map(([path, src]) => {
      const filename = filenameFromPath(path)
      const normalizedFilename = normalizeFilename(filename)
      const presentation = metadata[filename]

      return {
        id: normalizedFilename,
        path,
        src,
        filename,
        normalizedFilename,
        hasMetadata: Boolean(presentation),
        alt: presentation?.alt || deriveAltFromFilename(filename),
        caption: presentation?.caption,
        order: presentation?.order,
        objectPosition: presentation?.objectPosition || 'center',
        width: presentation?.width,
        height: presentation?.height,
      }
    })

  const byNormalizedFilename = new Map()
  for (const asset of entries) {
    const existing = byNormalizedFilename.get(asset.normalizedFilename)
    if (existing) {
      const duplicates = [existing.filename, asset.filename].sort(compareStrings)
      throw new Error(`Duplicate normalized Gallery filename: ${duplicates.join(', ')}`)
    }
    byNormalizedFilename.set(asset.normalizedFilename, asset)
  }

  return entries.sort(compareAssets)
}

export const orphanGalleryMetadata = findOrphanMetadata(
  galleryMetadata,
  Object.keys(discoveredModules),
)

if (orphanGalleryMetadata.length > 0) {
  throw new Error(`Gallery metadata has no matching asset: ${orphanGalleryMetadata.join(', ')}`)
}

export const galleryAssets = createGalleryAssets(discoveredModules)
