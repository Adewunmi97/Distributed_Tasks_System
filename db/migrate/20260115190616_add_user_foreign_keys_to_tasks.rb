class AddUserForeignKeysToTasks < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :tasks, :users, column: :creator_id
    add_foreign_key :tasks, :users, column: :assignee_id, on_delete: :nullify
  end
end
