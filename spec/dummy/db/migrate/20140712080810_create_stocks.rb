class CreateStocks < ActiveRecord::Migration
  def change
    create_table :stocks do |t|
      t.references :product
      t.integer :units
      t.timestamps
    end
  end
end
