class CustomEmoji < ApplicationRecord
  include ActionText::Attachable

  MAX_IMAGE_SIZE = 1.megabyte
  IMAGE_CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze
  NAME_PATTERN = /\A[a-z0-9][a-z0-9_]*\z/

  belongs_to :account
  belongs_to :creator, class_name: "User"

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [ 128, 128 ], format: :webp
  end

  before_validation :normalize_name

  validates :name,
    length: { in: 1..32 },
    format: { with: NAME_PATTERN, message: "can only contain lowercase letters, numbers, and underscores" },
    uniqueness: { scope: :account_id }
  validate :acceptable_image

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def activate
    update! active: true
  end

  def deactivate
    update! active: false
  end

  def manageable_by?(user)
    user.administrator? || creator == user
  end

  def display_variant
    image.variant(:display).processed if image.variable?
  end

  def to_attachable_partial_path
    "custom_emojis/attachment"
  end

  def attachable_content_type
    "application/vnd.campfire.custom-emoji"
  end

  def to_trix_content_attachment_partial_path
    "custom_emojis/attachment"
  end

  def attachable_plain_text_representation(_caption)
    ":#{name}:"
  end

  private
    def normalize_name
      self.name = name.to_s.strip.downcase.delete_prefix(":").delete_suffix(":")
    end

    def acceptable_image
      unless image.attached?
        errors.add :image, "must be selected"
        return
      end

      unless image.blob.content_type.in?(IMAGE_CONTENT_TYPES)
        errors.add :image, "must be a PNG, JPEG, or WebP image"
      end

      if image.blob.byte_size > MAX_IMAGE_SIZE
        errors.add :image, "must be smaller than 1 MB"
      end
    end
end
