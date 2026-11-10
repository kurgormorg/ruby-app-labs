class CreateApiTables < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.timestamps
    end
    create_table :jobs do |t|
      t.string :name, null: false
      t.string :place, null: false
      t.references :company, null: false, foreign_key: true
      t.boolean :deleted, null: false, default: false
      t.timestamps
    end
    create_table :geeks do |t|
      t.string :name, null: false
      t.string :stack, null: false
      t.text :resume
      t.timestamps
    end
    create_table :applies do |t|
      t.references :job, null: false, foreign_key: true
      t.references :geek, null: false, foreign_key: true
      t.boolean :read, null: false, default: false
      t.boolean :invited, null: false, default: false
      t.timestamps
    end
  end
end
