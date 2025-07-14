class Jobslurmid < ActiveRecord::Migration[6.1]
  def change
    add_column :jobs, :slurm_id, :integer
  end
end
