class RenameTypeColumnToSubscriptionList < ActiveRecord::Migration[5.1]
  def change
    rename_column :subscription_lists, :type , :record_type
  end
end
