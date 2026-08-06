class Autocompletable::CustomEmojisController < ApplicationController
  def index
    @custom_emojis = Current.account.custom_emojis.active.with_attached_image.ordered
  end
end
