import BaseAutocompleteHandler from "lib/autocomplete/base_autocomplete_handler"
import { PUNCTUATION_PATTERN } from "lib/autocomplete/constants"
import EMOJI_LIST from "lib/emoji/emoji_list"
import { Renderer } from "lib/autocomplete/renderer"

const MAX_RESULTS = 50

export default class extends BaseAutocompleteHandler {
  constructor(element, emojiUrl) {
    super(element)
    this.emojiUrl = emojiUrl
    this.emojiListPromise = null
    this.emojiList = null
    this.renderer = new Renderer()
  }

  get pattern() {
    return new RegExp(`^:(.*?)(${PUNCTUATION_PATTERN.source}*)$`)
  }

  loadAutocompletables(_query, callback) {
    if (this.emojiList) {
      this.setAutocompletables(this.emojiList)
      callback()
      return
    }

    if (!this.emojiListPromise) {
      this.emojiListPromise = this.fetchEmojiList()
    }

    this.emojiListPromise.then((emojiList) => {
      this.emojiList = emojiList
      this.setAutocompletables(emojiList)
      callback()
    })
  }

  insertAutocompletable(autocompletable, range, terminator, options = {}) {
    const emoji = autocompletable?.emoji || ""
    this.#insertEmojiAtRange(emoji, range, terminator, options)
  }

  fetchResultsForQuery(query, callback) {
    this.loadAutocompletables(query, () => {
      const autocompletables = this.autocompletablesMatchingQuery(query).slice(0, MAX_RESULTS)
      const html = this.renderer.renderAutocompletableSuggestions(autocompletables)
      callback(html)
    })
  }

  // Override to set selector's position relative to the cursor in the editor
  getOffsetsAtPosition(position) {
    return this.#getOffsetsFromEditorAtPosition(this.#editor, position)
  }

  #insertEmojiAtRange(emoji, range, terminator, { editor } = {}) {
    const targetEditor = editor || this.#editor
    if (!targetEditor || !emoji) return

    if (range) { targetEditor.setSelectedRange(range) }
    targetEditor.deleteInDirection("forward")
    targetEditor.insertString(emoji)
    targetEditor.insertString(terminator)
  }

  get #editor() {
    return this.element.editor
  }

  #getOffsetsFromEditorAtPosition(editor, position) {
    const rect = editor.getClientRectAtPosition(position)
    return rect ? rect : {}
  }

  async fetchEmojiList() {
    if (!this.emojiUrl) return EMOJI_LIST

    try {
      const response = await fetch(this.emojiUrl, { credentials: "same-origin" })
      if (!response.ok) throw new Error(`Emoji list fetch failed: ${response.status}`)
      const data = await response.json()
      if (!Array.isArray(data) || data.length === 0) return EMOJI_LIST
      return data
    } catch (_error) {
      return EMOJI_LIST
    }
  }
}
