class NGS::Run < ActiveRecord::Base

    has_many :libraries, dependent: :destroy

end
