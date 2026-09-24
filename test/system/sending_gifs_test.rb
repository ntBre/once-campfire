require "application_system_test_case"

class SendingGifsTest < ApplicationSystemTestCase
  setup do
    Rails.configuration.x.giphy.stubs(:api_key).returns("test-giphy-key")
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
    stub_giphy
  end

  test "searching and sending a GIF-only message, then editing and reloading it" do
    click_on "Choose a GIF"
    assert_selector ".gif-picker__result", count: 1
    fill_in "Search GIFs", with: "happy dog"
    find('[aria-label="Search GIFs"]').send_keys(:enter)
    assert_selector '[role="status"]', text: "Search results"
    assert_equal "happy dog", page.evaluate_script("window.giphyRequests.at(-1).q")
    assert_selector "dialog[open]"

    find(".gif-picker__result").click
    assert_no_selector "dialog[open]"
    assert_selector "trix-editor .giphy-gif"
    assert_no_match(/media\.giphy\.com/, find('input[name="message[body]"]', visible: false).value)

    click_on "send"
    assert_selector ".message[data-message-id] .giphy-gif"
    message = Message.order(:id).last
    assert_equal "[GIF] Happy dog", message.plain_text_body
    assert_not_includes message.body.body.to_html, "media.giphy.com"

    within_message message do
      reveal_message_actions
      find(".message__edit-btn").click
      assert_selector "trix-editor .giphy-gif"
      click_on "Save changes"
      assert_no_selector "trix-editor"
    end

    Rails.configuration.x.giphy.stubs(:api_key).returns(nil)
    join_room rooms(:designers)
    within_message message do
      assert_selector 'campfire-giphy-gif[href="https://giphy.com/gifs/abc123"]'
    end
    assert_not_includes message.reload.body.body.to_html, "media.giphy.com"
  end

  test "a quota error can be dismissed without losing the message draft" do
    fill_in_rich_text_area "message_body", with: "Keep this draft"
    page.execute_script "window.giphyStatus = 429"
    click_on "Choose a GIF"
    assert_text "GIPHY's hourly limit has been reached"
    click_on "Close GIF picker"
    assert_selector "trix-editor", text: "Keep this draft"
  end

  test "a missing key explains why GIF search is unavailable" do
    Rails.configuration.x.giphy.stubs(:api_key).returns(nil)
    join_room rooms(:designers)
    click_on "Choose a GIF"
    assert_text "GIF search is not configured."
  end

  private
    def stub_giphy
      page.execute_script <<~JS
        window.giphyRequests = []
        window.giphyStatus = 200
        const imageSource = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, "src")
        Object.defineProperty(HTMLImageElement.prototype, "src", {
          ...imageSource,
          set(value) {
            imageSource.set.call(this, value.startsWith("https://media.giphy.com/")
              ? "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
              : value)
          }
        })
        const fetch = window.fetch.bind(window)
        window.fetch = (input, options) => {
          const url = new URL(input, location.href)
          if (url.hostname !== "api.giphy.com") return fetch(input, options)
          window.giphyRequests.push(Object.fromEntries(url.searchParams))
          const image = { url: "https://media.giphy.com/media/abc123/giphy.gif?keep=this" }
          const gif = { id: "abc123", title: "Happy dog", images: {
            fixed_width: image, fixed_width_still: image, downsized: image
          } }
          return Promise.resolve(new Response(JSON.stringify({
            data: [gif], pagination: { total_count: 1 }
          }), { status: window.giphyStatus, headers: { "Content-Type": "application/json" } }))
        }
      JS
    end
end
