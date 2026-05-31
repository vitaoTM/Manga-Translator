class AddModelFieldsToTranslationBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :translation_batches, :model_provider, :string, null: false, default: "anthropic"
      add_column :translation_batches, :model_name, :string, null: false, default: "claude-sonnet-4-20250514"
  end
end
