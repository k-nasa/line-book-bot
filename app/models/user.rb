class User < ApplicationRecord
  validates :name, presence: true
  validates :line_id, presence: true , unipueness: true
end
