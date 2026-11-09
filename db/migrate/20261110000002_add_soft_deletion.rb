class AddSoftDeletion < ActiveRecord::Migration[8.1]
  def change
    %i[employees chats memberships messages].each do |table|
      add_column table, :deleted, :boolean, null: false, default: false
      add_index table, :deleted
    end
    add_index :memberships, [:employee_id, :chat_id], unique: true,
      where: "deleted = false", name: "unique_active_chat_membership"
  end
end
