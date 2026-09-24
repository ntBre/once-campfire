Rails.application.config.x.giphy.api_key = ENV["GIPHY_API_KEY"].presence

# Permit our renderer without allowing arbitrary Stimulus controllers in messages.
ActiveSupport.on_load(:action_text_content) do
  ActionText::ContentHelper.allowed_tags = (ActionText::ContentHelper.allowed_tags ||
    ActionText::ContentHelper.sanitizer.class.allowed_tags + [ ActionText::Attachment.tag_name, "figure", "figcaption" ]) + [ "campfire-giphy-gif" ]
end
