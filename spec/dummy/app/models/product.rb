class Product < ActiveRecord::Base
  has_many :stocks

  # for rspec
  has_many :dummy_stocks, class_name: Stock.name
end
