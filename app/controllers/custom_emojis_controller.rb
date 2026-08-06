class CustomEmojisController < ApplicationController
  before_action :set_custom_emoji, only: %i[ update destroy ]
  before_action :ensure_can_manage_custom_emoji, only: %i[ update destroy ]

  def index
    load_custom_emojis
    @custom_emoji = Current.account.custom_emojis.new
  end

  def create
    @custom_emoji = Current.account.custom_emojis.new(custom_emoji_params.merge(creator: Current.user))

    if @custom_emoji.save
      redirect_to custom_emojis_url, notice: "✓"
    else
      load_custom_emojis
      render :index, status: :unprocessable_content
    end
  end

  def update
    @custom_emoji.activate
    redirect_to custom_emojis_url, notice: "✓"
  end

  def destroy
    @custom_emoji.deactivate
    redirect_to custom_emojis_url, notice: "✓"
  end

  private
    def load_custom_emojis
      @custom_emojis = Current.account.custom_emojis.with_attached_image.includes(:creator).ordered
    end

    def set_custom_emoji
      @custom_emoji = Current.account.custom_emojis.find(params[:id])
    end

    def ensure_can_manage_custom_emoji
      head :forbidden unless @custom_emoji.manageable_by?(Current.user)
    end

    def custom_emoji_params
      params.require(:custom_emoji).permit(:name, :image)
    end
end
