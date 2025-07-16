class Addjobxref < ActiveRecord::Migration[6.1]
  def change
    create_table :xref_libraries_jobs do |t|
      t.string :library_id
      t.string :job_id
      t.date :created_at
      t.index ['library_id','job_id'], name: 'uniq_lib_job', unique: true
    end
  end
end
