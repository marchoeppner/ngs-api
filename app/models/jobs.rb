class NGS::Job < ActiveRecord::Base
    belongs_to :run
    belongs_to :pipeline
    has_many :xref_libraries_jobs
    has_many :libraries, through: :xref_libraries_jobs

    def remove
        if self.slurm_id
            if ["running", "pending", "submitted", "created"].include?(self.status)
                system("scancel #{self.slurm_id}")
            end
        end
        if File.directory?(self.run_dir)
            system("rm -Rf #{self.run_dir}")
        end
        self.destroy
    end
end