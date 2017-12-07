class User < ApplicationRecord
  validates :name ,presence: true
  validate :line_id , presence: true
end
