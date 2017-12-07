class AddTypeToSubscriptionList < ActiveRecord::Migration[5.1]
  def change
    add_column :subscription_lists, :type, :string
  end
end
