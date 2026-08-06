class CustomEmojis::ImagesController < ApplicationController
  include ActiveStorage::Streaming

  def show
    custom_emoji = CustomEmoji.find(params[:custom_emoji_id])

    if stale?(etag: custom_emoji)
      expires_in 1.hour, public: false, stale_while_revalidate: 1.day

      if variant = custom_emoji.display_variant
        send_webp_blob_file variant.key
      else
        head :not_found
      end
    end
  end

  private
    def send_webp_blob_file(key)
      send_file ActiveStorage::Blob.service.path_for(key), content_type: "image/webp", disposition: :inline
    end
end
