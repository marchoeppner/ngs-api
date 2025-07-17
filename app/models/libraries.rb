class NGS::Library < ActiveRecord::Base

    belongs_to :run
    has_many :xref_libraries_jobs
    has_many :jobs, through: :xref_libraries_jobs
    
end
