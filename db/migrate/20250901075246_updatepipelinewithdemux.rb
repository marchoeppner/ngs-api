class Updatepipelinewithdemux < ActiveRecord::Migration[6.1]
  def change
    add_column :pipelines, :demux, :boolean, :default => false
  end
end
