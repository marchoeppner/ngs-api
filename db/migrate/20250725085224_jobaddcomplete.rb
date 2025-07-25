class Jobaddcomplete < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :complete, :boolean, :default => false
  end
end
