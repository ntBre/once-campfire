import BaseAutocompleteHandler from "lib/autocomplete/base_autocomplete_handler"
import { PUNCTUATION_PATTERN } from "lib/autocomplete/constants"
import EMOJI_LIST from "lib/emoji/emoji_list"
import { Renderer } from "lib/autocomplete/renderer"
import { escapeHTML } from "helpers/dom_helpers"

const MAX_RESULTS = 50
const EMOJI_PUNCTUATION_PATTERN = new RegExp(PUNCTUATION_PATTERN.source.replace("\\u005F", ""))

export default class extends BaseAutocompleteHandler {
  constructor(element, emojiUrl, customEmojiUrl) {
    super(element)
    this.emojiUrl = emojiUrl
    this.customEmojiUrl = customEmojiUrl
    this.emojiListPromise = null
    this.emojiList = null
    this.renderer = new Renderer()
  }

  get pattern() {
    return new RegExp(`^:(.*?)(${EMOJI_PUNCTUATION_PATTERN.source}*)$`)
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
    if (autocompletable?.custom) {
      this.#insertCustomEmojiAtRange(autocompletable, range, terminator, options)
    } else {
      const emoji = autocompletable?.emoji || ""
      this.#insertEmojiAtRange(emoji, range, terminator, options)
    }
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

  #insertCustomEmojiAtRange(customEmoji, range, terminator, { editor } = {}) {
    const targetEditor = editor || this.#editor
    if (!targetEditor || !customEmoji.sgid || !customEmoji.image_url) return

    const name = escapeHTML(customEmoji.name)
    const imageUrl = escapeHTML(customEmoji.image_url)
    const content = `
      <span class="custom-emoji" title=":${name}:">
        <img src="${imageUrl}" class="custom-emoji__image" alt="" aria-hidden="true">
        <span class="for-screen-reader">:${name}:</span>
      </span>
    `
    const attachment = new Trix.Attachment({
      content,
      contentType: "application/vnd.campfire.custom-emoji",
      sgid: customEmoji.sgid
    })

    if (range) { targetEditor.setSelectedRange(range) }
    targetEditor.insertAttachment(attachment)
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
    const [customEmojis, unicodeEmojis] = await Promise.all([
      this.#fetchEmojiListFrom(this.customEmojiUrl, []),
      this.#fetchEmojiListFrom(this.emojiUrl, EMOJI_LIST)
    ])

    return customEmojis.concat(unicodeEmojis).map((emoji) => ({
      ...emoji,
      value: emoji.value || emoji.name,
      label: emoji.label || `:${emoji.name}:`
    }))
  }

  async #fetchEmojiListFrom(url, fallback) {
    if (!url) return fallback

    try {
      const response = await fetch(url, { credentials: "same-origin" })
      if (!response.ok) throw new Error(`Emoji list fetch failed: ${response.status}`)
      const data = await response.json()
      if (!Array.isArray(data)) return fallback
      return data
    } catch (_error) {
      return fallback
    }
  }
}
