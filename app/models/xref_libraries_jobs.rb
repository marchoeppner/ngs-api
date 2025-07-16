class NGS::XrefLibraryJob < ActiveRecord::Base

    belongs_to :job
    belongs_to :library
    
end
