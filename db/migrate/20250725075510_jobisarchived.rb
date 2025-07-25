class Jobisarchived < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :is_archived, :boolean, :default => false
  end
end
