class User < ApplicationRecord
  has_many :SubscriptionList , dependent: :destroy
  validates :name, presence: true
  validates :line_id, presence: true , uniqueness: true
end
