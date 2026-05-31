class CreateTranslationJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_jobs do |t|
      t.references :translation_batch, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :source_language
      t.text :translated_text
      t.string :error_message
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
