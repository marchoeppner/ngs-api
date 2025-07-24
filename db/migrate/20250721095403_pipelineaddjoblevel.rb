class Pipelineaddjoblevel < ActiveRecord::Migration[6.1]
  def change
    add_column :pipelines, :joblevel, :boolean, :default => false
  end
end
