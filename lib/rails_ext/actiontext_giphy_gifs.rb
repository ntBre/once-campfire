class ActionText::Attachment::GiphyGif
  include ActiveModel::Model

  CONTENT_TYPE = "application/vnd.campfire.giphy-gif"
  URL_PATTERN = %r{\Ahttps://giphy\.com/gifs/([a-zA-Z0-9]{1,100})\z}

  attr_accessor :href, :filename

  validates :href, format: { with: URL_PATTERN }

  def self.from_node(node)
    if node["content-type"] == CONTENT_TYPE
      # Lexxy stores custom attachment details in content; keep reading Trix attributes too.
      content = Nokogiri::HTML.fragment(node["content"].to_s).at_css("campfire-giphy-gif")
      attachment = new(href: node["href"] || content&.[]("href"), filename: node["filename"] || content&.text&.strip)
      attachment if attachment.valid?
    end
  end

  def gif_id
    href.match(URL_PATTERN)[1]
  end

  def title
    filename.presence || "GIF on GIPHY"
  end

  def attachable_content_type
    CONTENT_TYPE
  end

  def attachable_plain_text_representation(_caption)
    "[GIF] #{title}"
  end

  def to_partial_path
    "action_text/attachables/giphy_gif"
  end

  def to_trix_content_attachment_partial_path
    to_partial_path
  end
end
