class AddRecordTypeToBooks < ActiveRecord::Migration[5.1]
  def change
    add_column :books, :record_type, :string
  end
end
