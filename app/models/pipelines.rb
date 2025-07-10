class NGS::Pipeline < ActiveRecord::Base
    has_many :jobs, dependent: :destroy
end