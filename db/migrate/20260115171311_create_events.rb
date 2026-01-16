class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :event_type, null: false, limit: 100
      t.jsonb :payload, null: false, default: {}
      t.references :task, foreign_key: { on_delete: :cascade }
      t.datetime :processed_at

      t.timestamps
    end

    add_index :events, :event_type
    add_index :events, :processed_at
    add_index :events, :created_at
    add_index :events, :payload, using: :gin
  end
end
