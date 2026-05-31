class CreateTranslationBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_batches do |t|
      t.integer :status, null: false, default: 0
      t.string :title

      t.timestamps
    end
  end
end
