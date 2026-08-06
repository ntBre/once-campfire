require "test_helper"

class CustomEmojiTest < ActiveSupport::TestCase
  setup do
    @custom_emoji = build_custom_emoji
  end

  test "normalizes its name" do
    @custom_emoji.name = ":Party_Parrot:"

    assert @custom_emoji.save
    assert_equal "party_parrot", @custom_emoji.name
    assert_equal ":party_parrot:", @custom_emoji.attachable_plain_text_representation(nil)
  end

  test "requires a safe name" do
    @custom_emoji.name = "party parrot"

    assert_not @custom_emoji.valid?
    assert_includes @custom_emoji.errors[:name], "can only contain lowercase letters, numbers, and underscores"
  end

  test "requires a unique account-wide name" do
    assert @custom_emoji.save

    duplicate = build_custom_emoji(name: @custom_emoji.name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires a supported image" do
    @custom_emoji.image.attach io: file_fixture("pixel.bmp").open, filename: "pixel.bmp", content_type: "image/bmp"

    assert_not @custom_emoji.valid?
    assert_includes @custom_emoji.errors[:image], "must be a PNG, JPEG, or WebP image"
  end

  test "deactivation keeps the record and image for historical messages" do
    @custom_emoji.save!

    assert_no_difference -> { CustomEmoji.count } do
      @custom_emoji.deactivate
    end

    assert_not @custom_emoji.active?
    assert @custom_emoji.image.attached?
  end

  test "renders as an Action Text attachment with shortcode plain text" do
    @custom_emoji.save!
    attachment = %(<action-text-attachment sgid="#{@custom_emoji.attachable_sgid}" content-type="application/vnd.campfire.custom-emoji"></action-text-attachment>)
    message = Message.create! room: rooms(:pets), creator: users(:jason), body: "<div>#{attachment}</div>"

    assert_equal ":party_parrot:", message.plain_text_body
    assert_includes message.body.to_s, "custom-emoji__image"
    assert_no_match(/<figure|attachment--file/, message.body.to_s)
    assert_not message.attachment.attached?
  end

  private
    def build_custom_emoji(name: "party_parrot")
      CustomEmoji.new(account: accounts(:signal), creator: users(:kevin), name: name).tap do |custom_emoji|
        custom_emoji.image.attach io: file_fixture("moon.jpg").open, filename: "moon.jpg", content_type: "image/jpeg"
      end
    end
end
