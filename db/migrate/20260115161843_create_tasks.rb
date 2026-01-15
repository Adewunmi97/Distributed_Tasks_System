class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :state, null: false, default: 'draft'
      t.references :creator, null: false, foreign_key: { to_table: :users }, index: true
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }, index: true

      t.timestamps
    end

    add_index :tasks, :state
    add_index :tasks, [:assignee_id, :state]
  end
end