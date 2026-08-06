require "test_helper"

class CustomEmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "any member can view custom emoji" do
    get custom_emojis_url

    assert_response :ok
    assert_select "h1", "Custom emoji"
  end

  test "any member can upload custom emoji" do
    assert_difference -> { CustomEmoji.count }, 1 do
      post custom_emojis_url, params: {
        custom_emoji: {
          name: "Party_Parrot",
          image: fixture_file_upload("moon.jpg", "image/jpeg")
        }
      }
    end

    assert_redirected_to custom_emojis_url
    assert_equal "party_parrot", CustomEmoji.last.name
    assert_equal users(:kevin), CustomEmoji.last.creator
  end

  test "uploader can remove and restore custom emoji" do
    custom_emoji = create_custom_emoji(creator: users(:kevin))

    delete custom_emoji_url(custom_emoji)
    assert_redirected_to custom_emojis_url
    assert_not custom_emoji.reload.active?

    patch custom_emoji_url(custom_emoji)
    assert_redirected_to custom_emojis_url
    assert custom_emoji.reload.active?
  end

  test "another member cannot remove custom emoji" do
    custom_emoji = create_custom_emoji(creator: users(:jz))

    delete custom_emoji_url(custom_emoji)

    assert_response :forbidden
    assert custom_emoji.reload.active?
  end

  test "administrator can remove another member's custom emoji" do
    custom_emoji = create_custom_emoji(creator: users(:kevin))
    sign_in :david

    delete custom_emoji_url(custom_emoji)

    assert_redirected_to custom_emojis_url
    assert_not custom_emoji.reload.active?
  end

  private
    def create_custom_emoji(creator:)
      CustomEmoji.new(account: accounts(:signal), creator: creator, name: "party_parrot").tap do |custom_emoji|
        custom_emoji.image.attach io: file_fixture("moon.jpg").open, filename: "moon.jpg", content_type: "image/jpeg"
        custom_emoji.save!
      end
    end
end
