class User < ApplicationRecord
  has_many :SubscriptionList
  validates :name, presence: true
  validates :line_id, presence: true , uniqueness: true
end
