import { apiKey, loadGif, mediaUrl } from "lib/giphy"

Trix.config.dompurify.ADD_TAGS = [ ...(Trix.config.dompurify.ADD_TAGS || []), "campfire-giphy-gif" ]

// Shadow DOM keeps temporary media URLs out of Trix/Action Text serialization.
class GiphyGif extends HTMLElement {
  connectedCallback() {
    this.generation = (this.generation || 0) + 1
    if (!this.shadowRoot) this.attachShadow({ mode: "open" })
    this.shadowRoot.replaceChildren(document.createElement("slot"))
    this.gifId = this.getAttribute("href")?.match(/^https:\/\/giphy\.com\/gifs\/([a-zA-Z0-9]{1,100})$/)?.[1]
    if (!apiKey() || !this.gifId) return

    this.observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.observer.disconnect()
        this.load()
      }
    })
    this.observer.observe(this)
  }

  disconnectedCallback() {
    this.generation++
    this.observer?.disconnect()
  }

  async load() {
    const generation = this.generation
    try {
      const gif = await loadGif(this.gifId)
      if (!this.isConnected || generation !== this.generation) return
      const url = gif && mediaUrl(gif)
      if (!url) return

      const link = document.createElement("a")
      link.href = this.getAttribute("href")
      link.target = "_blank"
      link.rel = "noopener noreferrer"
      const image = document.createElement("img")
      image.src = url
      image.alt = gif.title || "GIF"
      image.style = "display: block; max-width: 100%; max-height: 20rem; border-radius: 0.4rem; object-fit: contain"
      image.addEventListener("error", () => link.remove(), { once: true })
      link.append(image)
      this.shadowRoot.prepend(link)
    } catch (_error) {
      // Keep the page link usable if the key, quota, or GIF is unavailable.
    }
  }
}

customElements.define("campfire-giphy-gif", GiphyGif)
