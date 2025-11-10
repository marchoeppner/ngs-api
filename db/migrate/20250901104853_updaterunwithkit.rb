class Updaterunwithkit < ActiveRecord::Migration[6.1]
  def change
    add_column :runs, :kit, :string
  end
end
