class Addpipelinetojob < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :pipeline_id, :integer
  end
end
