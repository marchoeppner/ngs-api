class NGS::Job < ActiveRecord::Base
    belongs_to :run
    belongs_to :pipeline
    has_many :xref_libraries_jobs
end