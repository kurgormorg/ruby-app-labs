class CreateMessenger < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :department, null: false
      t.text :bio
      t.timestamps
    end
    add_index :employees, :email, unique: true
    create_table :chats do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "group"
      t.text :description
      t.timestamps
    end
    create_table :memberships do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.string :role, null: false, default: "member"
      t.boolean :muted, null: false, default: false
      t.datetime :last_read_at
      t.timestamps
    end
    create_table :messages do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :messages, [:chat_id, :created_at]
  end
end
