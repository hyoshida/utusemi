class Stock < ActiveRecord::Base
  belongs_to :product

  scope :unsold, -> { where('quantity > ?', 0) }
end
