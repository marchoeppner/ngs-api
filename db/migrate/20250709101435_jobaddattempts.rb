class Jobaddattempts < ActiveRecord::Migration[6.1]
  def change
     add_column :jobs, :attempts, :integer
  end
end
