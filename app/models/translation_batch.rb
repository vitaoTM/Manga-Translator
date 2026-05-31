class TranslationBatch < ApplicationRecord
  has_many :translation_jobs, -> { ordered(:position) }, dependent: :destroy

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, prefix: true
end
