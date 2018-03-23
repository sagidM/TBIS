class Company < ApplicationRecord
  belongs_to :user
  has_many :affiliates, dependent: :destroy

  validates :name, presence: true
end