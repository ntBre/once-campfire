import * as Lexxy from "lexxy"
import CiteNode from "lib/rich_text/cite_node"

const {
  $createParagraphNode, $getSelection, $isLineBreakNode, $isParagraphNode,
  $isRangeSelection, $isRootOrShadowRoot, $isTextNode,
  COMMAND_PRIORITY_HIGH, KEY_ENTER_COMMAND
} = Lexxy.Lexical

export default class CampfireRichTextExtension extends Lexxy.Extension {
  get allowedElements() {
    return [
      "cite",
      "figure",
      "figcaption",
      "actiontext-opengraph-embed",
      { tag: "div", attributes: [ "sgid" ] },
      { tag: "span", attributes: [ "sgid" ] },
      { tag: "img", attributes: [ "alt" ] },
      { tag: "a", attributes: [ "rel", "target" ] }
    ]
  }

  get lexicalExtension() {
    return this.defineExtension({
      name: "campfire/rich-text",
      nodes: [ CiteNode ],
      register: editor => editor.registerCommand(
        KEY_ENTER_COMMAND,
        event => this.#startCodeBlock(editor, event),
        COMMAND_PRIORITY_HIGH
      )
    })
  }

  #startCodeBlock(editor, event) {
    if (!event?.shiftKey || event.ctrlKey || event.metaKey || event.altKey || event.isComposing || editor.isComposing()) return false
    if (!this.editorElement.supportsMarkdown || !this.editorElement.supportsMultiLine || this.editorElement.hasOpenPrompt) return false

    const selection = $getSelection()
    if (!$isRangeSelection(selection) || !selection.isCollapsed()) return false

    const anchor = selection.anchor.getNode()
    if (!$isTextNode(anchor) || selection.anchor.offset !== anchor.getTextContentSize() || anchor.getNextSibling()) return false

    const paragraph = anchor.getParent()
    if (!$isParagraphNode(paragraph) || !$isRootOrShadowRoot(paragraph.getParent())) return false

    const previous = anchor.getPreviousSibling()
    if (previous && !$isLineBreakNode(previous)) return false
    if (anchor.hasFormat("code") || !/^```[\w-]*$/.test(anchor.getTextContent())) return false

    // Shift+Enter keeps lines in one paragraph. Give the fence its own
    // paragraph so Lexical recognizes it as a block-level Markdown shortcut.
    if (previous) {
      const fence = $createParagraphNode()
      paragraph.insertAfter(fence)
      fence.append(anchor)
      previous.remove()
      fence.selectEnd()
    }

    // Invoke Lexical's normal fence conversion without sending another DOM
    // keydown through Campfire's Enter-to-send handler.
    event.preventDefault()
    return editor.dispatchCommand(KEY_ENTER_COMMAND, new KeyboardEvent("keydown", { key: "Enter" }))
  }
}
