class AddBubblePipelineToTranslationJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :translation_jobs, :bubble_detection_status, :integer, default: 0, null: false
    add_column :translation_jobs, :bubble_count,            :integer, default: 0, null: false
  end
end
