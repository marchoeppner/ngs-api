class Adddependtojob < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :depends_on, :integer
  end
end
