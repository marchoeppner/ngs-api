class NGS::XrefLibrariesJob < ActiveRecord::Base

    belongs_to :job
    belongs_to :library
    
end
