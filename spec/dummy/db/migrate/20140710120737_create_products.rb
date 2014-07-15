class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :title
      t.string :description1
      t.string :description2
      t.string :description3
      t.timestamps
    end
  end
end
