json.name      custom_emoji.name
json.value     "custom-#{custom_emoji.id}"
json.label     ":#{custom_emoji.name}:"
json.image_url custom_emoji_image_url(custom_emoji)
json.sgid      custom_emoji.attachable_sgid
json.custom    true
