class Libraries < ActiveRecord::Migration[6.1]
  def change
    create_table :libraries do |t|
      t.integer :run_id
      t.string :name
      t.string :R1
      t.string :R2
      t.date :date_registered
    end
  end
end
