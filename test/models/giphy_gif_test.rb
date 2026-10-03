require "test_helper"

class GiphyGifTest < ActiveSupport::TestCase
  test "GIF attachments survive storage and have a useful plain text representation" do
    message = Message.create! room: rooms(:pets), creator: users(:jason), body: attachment_html
    attachment = message.reload.body.body.attachments.sole.attachable

    assert_instance_of ActionText::Attachment::GiphyGif, attachment
    assert_equal "abc123", attachment.gif_id
    assert_equal "[GIF] Happy dog", message.plain_text_body
    assert_includes message.body.to_trix_html, "application/vnd.campfire.giphy-gif"
    assert_includes message.body.to_trix_html, "https://giphy.com/gifs/abc123"
    assert_not_includes message.body.to_trix_html, "media.giphy.com"
  end

  test "only exact GIPHY page URLs and content types are recognized" do
    [ "https://giphy.com.evil.test/gifs/abc123", "javascript:alert(1)",
      "http://giphy.com/gifs/abc123", "https://giphy.com/gifs/abc123?other=1",
      "https://giphy.com/gifs/../test", "https://giphy.com/gifs/" ].each do |href|
      node = ActionText::Fragment.wrap(attachment_html(href: href)).find_all(ActionText::Attachment.tag_name).first
      assert_nil ActionText::Attachment::GiphyGif.from_node(node), href
    end

    node = ActionText::Fragment.wrap(attachment_html.sub("giphy-gif", "giphy-gif-fake")).find_all(ActionText::Attachment.tag_name).first
    assert_nil ActionText::Attachment::GiphyGif.from_node(node)
  end

  test "rendering uses validated attributes instead of supplied attachment HTML" do
    body = attachment_html.sub(">", ' content="&lt;img src=&quot;https://evil.test/a.gif&quot;&gt;">')
    message = Message.create! room: rooms(:pets), creator: users(:jason), body: body
    filtered = ContentFilters::TextMessagePresentationFilters.apply(message.body.body)
    html = ApplicationController.helpers.message_presentation(message)

    assert_includes filtered.to_html, "action-text-attachment"
    assert_includes html, '<campfire-giphy-gif class="giphy-gif" href="https://giphy.com/gifs/abc123">'
    assert_not_includes html, "evil.test"
  end

  test "Lexxy content survives storage and is rendered from validated metadata" do
    content = '<campfire-giphy-gif href="https://giphy.com/gifs/abc123"><a>Happy dog</a><img src="https://evil.test/a.gif"></campfire-giphy-gif>'
    body = %(<action-text-attachment content-type="application/vnd.campfire.giphy-gif" content="#{ERB::Util.html_escape(content)}"></action-text-attachment>)
    message = Message.create! room: rooms(:pets), creator: users(:jason), body: body

    assert_equal "[GIF] Happy dog", message.reload.plain_text_body
    assert_equal "abc123", message.body.body.attachments.sole.attachable.gif_id
    assert_includes message.body.to_trix_html, "https://giphy.com/gifs/abc123"
    assert_not_includes ApplicationController.helpers.message_presentation(message), "evil.test"
  end

  test "Lexxy content rejects non-GIPHY links and missing metadata" do
    [ '<campfire-giphy-gif href="https://evil.test/gifs/abc123">Dog</campfire-giphy-gif>',
      '<a href="https://giphy.com/gifs/abc123">Dog</a>', "" ].each do |content|
      node = Nokogiri::HTML.fragment(attachment_html).at_css("action-text-attachment")
      node.remove_attribute("href")
      node["content"] = content
      assert_nil ActionText::Attachment::GiphyGif.from_node(node)
    end
  end

  private
    def attachment_html(href: "https://giphy.com/gifs/abc123")
      %(<action-text-attachment content-type="application/vnd.campfire.giphy-gif" href="#{href}" filename="Happy dog"></action-text-attachment>)
    end
end
