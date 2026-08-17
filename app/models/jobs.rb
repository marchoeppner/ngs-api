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
            Dir.chdir(self.run_dir) do |dir|
                files = Dir["*.*"]
                # first unlink symlinked files to not delete original data
                files.each do |file|
                    if File.symlink?(file)
                        File.unlink(file)
                    end
                end
            end 
            system("rm -Rf #{self.run_dir}")
        end
        self.destroy
    end
end