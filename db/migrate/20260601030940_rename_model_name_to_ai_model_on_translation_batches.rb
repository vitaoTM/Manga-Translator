class RenameModelNameToAiModelOnTranslationBatches < ActiveRecord::Migration[8.1]
  def change
    rename_column :translation_batches, :model_name, :ai_model
  end
end
