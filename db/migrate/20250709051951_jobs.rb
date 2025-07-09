class Jobs < ActiveRecord::Migration[6.1]
  def change
    create_table :jobs do |t|
      t.string :name
      t.string :description
      t.string :status
      t.string :command
      t.string :run_dir
      t.string :options
      t.string :log
      t.date :date_registered
      t.date :date_updated
    end
  end
end
