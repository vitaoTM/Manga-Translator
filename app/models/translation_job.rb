class TranslationJob < ApplicationRecord
  belongs_to :translation_batch
  has_one_attached :image

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, prefix: true

  validates :image, presence: true
end
