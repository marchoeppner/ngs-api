class NGS::Job < ActiveRecord::Base
    belongs_to :run
    belongs_to :pipeline
end