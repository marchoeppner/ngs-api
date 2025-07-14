class Adduniquepipe < ActiveRecord::Migration[6.1]
  def change
    change_table :pipelines do |t|
      t.index ['name'], name: 'uniq_pipeline', unique: true
    end
  end
end
