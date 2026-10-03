require "test_helper"

class Autocompletable::EmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "returns Unicode emoji as editable text" do
    get autocompletable_emojis_url, params: { filter: "GRINNING_FACE" }

    assert_response :ok
    assert_select "lexxy-prompt-item[search=grinning_face] template[type=editor]", text: "😀"
    assert_select "lexxy-prompt-item", maximum: 50
  end

  test "searches Unicode descriptions" do
    get autocompletable_emojis_url, params: { filter: "smiling" }

    assert_response :ok
    assert_select "lexxy-prompt-item[search=grinning_face]"
  end

  test "returns only matching active custom emoji with signed attachments" do
    active = create_custom_emoji("party_parrot")
    create_custom_emoji("party_retired", active: false)
    create_custom_emoji("another_bird")

    get autocompletable_emojis_url, params: { filter: "PARTY_" }

    assert_response :ok
    assert_select "lexxy-prompt-item[search=party_retired]", count: 0
    assert_select "lexxy-prompt-item[search=another_bird]", count: 0
    assert_select "lexxy-prompt-item[search=party_parrot] template[type=editor] action-text-attachment" do |nodes|
      attachment = nodes.first
      assert_equal active.attachable_sgid, attachment["sgid"]
      assert_equal "application/vnd.campfire.custom-emoji", attachment["content-type"]
      assert_includes attachment["content"], custom_emoji_image_path(active)
      assert_includes attachment["content"], "custom-emoji__image"
    end
  end

  test "returns a limited mixed menu and empty results for unmatched queries" do
    create_custom_emoji("party_parrot")

    get autocompletable_emojis_url

    assert_select "lexxy-prompt-item", count: 50
    assert_select "lexxy-prompt-item[search=party_parrot]"
    assert_select "lexxy-prompt-item template[type=editor] action-text-attachment", count: 1

    get autocompletable_emojis_url, params: { filter: "no_such_emoji" }

    assert_response :ok
    assert_select "lexxy-prompt-item", count: 0
  end

  private
    def create_custom_emoji(name, active: true)
      CustomEmoji.new(account: accounts(:signal), creator: users(:kevin), name: name, active: active).tap do |emoji|
        emoji.image.attach io: file_fixture("moon.jpg").open, filename: "moon.jpg", content_type: "image/jpeg"
        emoji.save!
      end
    end
end
