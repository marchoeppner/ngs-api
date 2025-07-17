class Pipelineaddrunlevel < ActiveRecord::Migration[6.1]
  def change
    add_column :pipelines, :runlevel, :boolean, :default => false
  end
end
