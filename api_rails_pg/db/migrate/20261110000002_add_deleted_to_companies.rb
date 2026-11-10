class AddDeletedToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :deleted, :boolean, null: false, default: false
  end
end
