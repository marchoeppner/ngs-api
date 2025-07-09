class Runs < ActiveRecord::Migration[6.1]
  def change
    create_table :runs do |t|
      t.string :platform
      t.string :name
      t.string :description
      t.string :folder
      t.date :date_registered
    end
  end
end
