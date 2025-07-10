class NGS::Run < ActiveRecord::Base

    has_many :libraries, dependent: :destroy
    has_many :jobs, dependent: :destroy

end
