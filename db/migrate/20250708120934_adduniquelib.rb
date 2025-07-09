class Adduniquelib < ActiveRecord::Migration[6.1]
  def change
    change_table :libraries do |t|
      t.index ['name', 'lane', "run_id"], name: 'uniq_library_by_lane_and_run', unique: true
    end
  end
end
