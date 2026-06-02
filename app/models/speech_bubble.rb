class SpeechBubble < ApplicationRecord
  belongs_to :translation_job

  validates :bbox_x, :bbox_y, :bbox_w, :bbox_h, presence: true
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  scope :ordered, -> { order(:position) }
  scope :with_text, -> { where.not(raw_text: [ nil, "" ]) }
  scope :translated, -> { where.not(translated_text: [ nil, "" ]) }

  def bbox
    { x: bbox_x, y: bbox_y, w: bbox_w, h: bbox_h }
  end

  def pixel_bbox(img_width, img_height)
    {
      x: (bbox_x * img_width).round,
      y: (bbox_y * img_height).round,
      w: (bbox_w * img_width).round,
      h: (bbox_h * img_height).round
    }
  end
end
