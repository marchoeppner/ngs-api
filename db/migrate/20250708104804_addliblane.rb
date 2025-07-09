class Addliblane < ActiveRecord::Migration[6.1]
  def change
     add_column :libraries, :lane, :integer
  end
end
