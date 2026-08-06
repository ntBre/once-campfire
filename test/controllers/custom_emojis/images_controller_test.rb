require "test_helper"

class CustomEmojis::ImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "shows the processed image for active and inactive custom emoji" do
    custom_emoji = CustomEmoji.new(account: accounts(:signal), creator: users(:kevin), name: "party_parrot", active: false)
    custom_emoji.image.attach io: file_fixture("moon.jpg").open, filename: "moon.jpg", content_type: "image/jpeg"
    custom_emoji.save!

    get custom_emoji_image_url(custom_emoji)

    assert_response :ok
    assert_equal "image/webp", response.content_type
  end
end
