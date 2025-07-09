class Pipelines < ActiveRecord::Migration[6.1]
  def change
    create_table :pipelines do |t|
      t.string :name
      t.string :description
      t.string :version
      t.string :template
      t.string :samplesheet_format
    end
  end
end
