class Jobaddreport < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :report, :string
  end
end
