class CreateSubscriptionLists < ActiveRecord::Migration[5.1]
  def change
    create_table :subscription_lists do |t|
      t.string :content
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
