export const GIF_CONTENT_TYPE = "application/vnd.campfire.giphy-gif"
const pending = new Map()
let batchTimer

export function apiKey() {
  return document.querySelector('meta[name="giphy-api-key"]')?.content
}

export function gifUrl(id) {
  if (!/^[a-zA-Z0-9]{1,100}$/.test(id)) throw new Error("Invalid GIF ID")
  return `https://giphy.com/gifs/${id}`
}

export async function request(path, parameters = {}, signal) {
  const key = apiKey()
  if (!key) throw new Error("GIF search is not configured.")

  const url = new URL(`https://api.giphy.com/v1/gifs${path}`)
  url.search = new URLSearchParams({ api_key: key, ...parameters })
  const response = await fetch(url, { signal, credentials: "omit", cache: "no-store" })

  if (response.status === 429) throw new Error("GIPHY's hourly limit has been reached. Try again later.")
  if (response.status === 401 || response.status === 403) throw new Error("GIPHY rejected the API key.")
  if (!response.ok) throw new Error("GIPHY is unavailable. Try again.")
  return response.json()
}

export function mediaUrl(gif, preview = false) {
  const images = gif.images || {}
  const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
  const rendition = still ? images.fixed_width_still : preview ? images.fixed_width : images.downsized || images.original
  const value = rendition?.url
  if (!value) return null

  const url = new URL(value)
  if (url.protocol !== "https:" || !(url.hostname === "giphy.com" || url.hostname.endsWith(".giphy.com"))) return null
  return value // Preserve the URL and its query parameters exactly as returned.
}

// Only coalesce simultaneous lookups; do not persist media URLs or API responses.
export function loadGif(id) {
  gifUrl(id)
  if (!pending.has(id)) {
    let resolve, reject
    const promise = new Promise((yes, no) => { resolve = yes; reject = no })
    pending.set(id, { promise, resolve, reject })
  }
  clearTimeout(batchTimer)
  batchTimer = setTimeout(flush, 30)
  return pending.get(id).promise
}

async function flush() {
  const entries = Array.from(pending.entries())
  pending.clear()

  for (let offset = 0; offset < entries.length; offset += 50) {
    const batch = entries.slice(offset, offset + 50)
    try {
      const { data } = await request("", { ids: batch.map(([id]) => id).join(",") })
      const gifs = new Map(data.map(gif => [gif.id, gif]))
      batch.forEach(([id, { resolve }]) => resolve(gifs.get(id)))
    } catch (error) {
      batch.forEach(([, { reject }]) => reject(error))
    }
  }
}
