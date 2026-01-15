class RemoveUserForeignKeysFromTasks < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :tasks, column: :creator_id
    remove_foreign_key :tasks, column: :assignee_id
  end
end
