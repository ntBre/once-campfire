require "test_helper"

class Autocompletable::CustomEmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "returns active custom emoji as autocomplete entries" do
    active = create_custom_emoji(name: "party_parrot")
    create_custom_emoji(name: "retired_parrot", active: false)

    get autocompletable_custom_emojis_url

    assert_response :ok
    entries = response.parsed_body
    assert_equal 1, entries.size
    assert_equal({
      "name" => "party_parrot",
      "value" => "custom-#{active.id}",
      "label" => ":party_parrot:",
      "image_url" => custom_emoji_image_url(active),
      "sgid" => active.attachable_sgid,
      "custom" => true
    }, entries.first)
  end

  private
    def create_custom_emoji(name:, active: true)
      CustomEmoji.new(account: accounts(:signal), creator: users(:kevin), name: name, active: active).tap do |custom_emoji|
        custom_emoji.image.attach io: file_fixture("moon.jpg").open, filename: "moon.jpg", content_type: "image/jpeg"
        custom_emoji.save!
      end
    end
end
