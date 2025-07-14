class Addlibrarystatus < ActiveRecord::Migration[6.1]
  def change
    add_column :libraries, :active, :boolean, :default => true
  end
end
