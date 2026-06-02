class TranslationJob < ApplicationRecord
  belongs_to :translation_batch
  has_one_attached :image
  has_one_attached :rendered_image
  has_many :speech_bubbles, -> { order(:position) }, dependent: :destroy

  enum :status, {
    pending:    0,
    processing: 1,
    completed:  2,
    failed:     3
  }, prefix: true

  enum :bubble_detection_status, {
    bubbles_pending:   0,
    bubbles_detecting: 1,
    bubbles_detected:  2,
    bubbles_failed:    3
  }, prefix: true

  validates :image, presence: true
end
