class Autocompletable::EmojisController < ApplicationController
  MAX_RESULTS = 50
  UNICODE_EMOJIS = JSON.parse(Rails.root.join("app/assets/emoji/emoji_list.json").read).freeze

  def index
    @custom_emojis = Current.account.custom_emojis.active.with_attached_image.ordered
      .where("name LIKE ? ESCAPE '\\'", "%#{CustomEmoji.sanitize_sql_like(query)}%")
      .limit(MAX_RESULTS).to_a
    @unicode_emojis = UNICODE_EMOJIS.select { |emoji| emoji["name"].include?(query) || emoji["description"].include?(query) }
      .sort_by { |emoji| [ emoji["name"].start_with?(query) ? 0 : 1, emoji["name"] ] }
      .first(MAX_RESULTS - @custom_emojis.size)

    render layout: false
  end

  private
    def query
      @query ||= params[:filter].to_s.downcase
    end
end
