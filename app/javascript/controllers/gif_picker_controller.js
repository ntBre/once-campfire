import { Lexical } from "lexxy"
import { Controller } from "@hotwired/stimulus"
import { GIF_CONTENT_TYPE, gifUrl, mediaUrl, request } from "lib/giphy"

export default class extends Controller {
  static targets = [ "dialog", "query", "results", "status", "more", "editor" ]

  disconnect() {
    this.abortController?.abort()
  }

  open() {
    this.selection = this.editorTarget.editor.getEditorState().read(() => Lexical.$getSelection()?.clone())
    this.dialogTarget.showModal()
    this.queryTarget.focus()
    this.search()
  }

  close() {
    this.dialogTarget.close()
  }

  closed() {
    this.abortController?.abort()
    this.resultsTarget.replaceChildren()
    this.gifs = []
    this.editorTarget.focus()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      const { left, right, top, bottom } = this.dialogTarget.getBoundingClientRect()
      if (event.clientX < left || event.clientX > right || event.clientY < top || event.clientY > bottom) this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  search() {
    this.query = this.queryTarget.value.trim()
    this.offset = 0
    this.gifs = []
    this.resultsTarget.replaceChildren()
    this.fetchResults()
  }

  more() {
    this.fetchResults()
  }

  async fetchResults() {
    this.abortController?.abort()
    const controller = this.abortController = new AbortController()
    this.moreTarget.hidden = true
    this.resultsTarget.setAttribute("aria-busy", "true")
    this.statusTarget.textContent = "Loading GIFs…"

    try {
      const { data, pagination } = await request(this.query ? "/search" : "/trending", {
        ...(this.query ? { q: this.query } : {}), limit: 24, offset: this.offset, rating: "pg-13"
      }, controller.signal)
      if (controller.signal.aborted) return

      for (const gif of data) {
        const index = this.gifs.push(gif) - 1
        this.resultsTarget.append(this.resultButton(gif, index))
      }
      this.offset += data.length
      this.moreTarget.hidden = !data.length || this.offset >= pagination.total_count || this.offset > (this.query ? 4999 : 499)
      this.statusTarget.textContent = this.gifs.length ? (this.query ? "Search results" : "Trending GIFs") : "No GIFs found. Try another search."
    } catch (error) {
      if (!controller.signal.aborted) {
        this.statusTarget.textContent = error.message || "Could not load GIFs. Try again."
        this.moreTarget.hidden = this.offset === 0
      }
    } finally {
      if (this.abortController === controller) this.resultsTarget.setAttribute("aria-busy", "false")
    }
  }

  resultButton(gif, index) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "gif-picker__result"
    button.dataset.action = "gif-picker#choose"
    button.dataset.gifPickerIndexParam = index
    button.setAttribute("aria-label", gif.title || "Choose GIF")
    const url = mediaUrl(gif, true)
    if (url) {
      const image = document.createElement("img")
      image.src = url
      image.alt = gif.title || "GIF"
      image.loading = "lazy"
      button.append(image)
    } else {
      button.textContent = gif.title || "GIF"
    }
    return button
  }

  choose(event) {
    const gif = this.gifs[event.params.index]
    const href = gifUrl(gif.id)
    // The durable attachment contains only an ID/page link and text, never a media URL.
    const content = document.createElement("campfire-giphy-gif")
    content.className = "giphy-gif"
    content.setAttribute("href", href)
    const link = document.createElement("a")
    link.className = "giphy-gif__link"
    link.href = href
    link.textContent = gif.title || "GIF on GIPHY"
    link.target = "_blank"
    link.rel = "noopener noreferrer"
    content.append(link)

    const attachment = document.createElement("action-text-attachment")
    attachment.setAttribute("content-type", GIF_CONTENT_TYPE)
    attachment.setAttribute("content", content.outerHTML)

    this.editorTarget.editor.update(() => {
      if (this.selection) Lexical.$setSelection(this.selection)
      this.editorTarget.contents.insertHtml(attachment.outerHTML)
    }, { tag: "history-push" })
    this.close()
  }
}
