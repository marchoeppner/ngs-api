class Addruntojob < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :run_id, :integer
  end
end
