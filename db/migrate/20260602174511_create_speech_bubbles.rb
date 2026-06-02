class CreateSpeechBubbles < ActiveRecord::Migration[8.1]
  def change
    create_table :speech_bubbles do |t|
      t.references :translation_job, null: false, foreign_key: true
      t.float :bbox_x, null: false
      t.float :bbox_y, null: false
      t.float :bbox_w, null: false
      t.float :bbox_h, null: false
      t.float :confidence, null: false, default: 0.0
      t.text :raw_text
      t.text :translated_text
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :speech_bubbles, [ :translation_job_id, :position ]
  end
end
