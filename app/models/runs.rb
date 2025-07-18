class NGS::Run < ActiveRecord::Base

    has_many :libraries, dependent: :destroy
    has_many :jobs, dependent: :destroy
    has_many :pipelines, through: :jobs

    def runlevel_jobs

        return self.jobs.select {|j| j.pipeline.runlevel }

    end

    def library_jobs

        return self.jobs.select {|j| !j.pipeline.runlevel }

    end

    def register_libraries

        data = Dir["#{self.folder}/**/*.fastq.gz"].group_by{|f| File.basename(f).split(/_L00[0-9]_R[1,2]/)[0]}
        data.each do |lib,reads|
            # group by lane
            reads.group_by{|r| File.basename(r).slice(/L[0-9]*/) }.each do |b,fastqs|
                lane = b.split("L00")[-1]
                fwd = nil
                rev = nil
                if fastqs.length == 2
                    fwd,rev = fastqs.sort
                else
                    fwd = fastqs
                end
                if NGS::Library.where(R1: fwd, run_id: self.id, lane: lane).empty?
                    payload = { "run_id" => self.id, "name" => lib, "R1" => fwd, "R2" => rev, "lane" => lane , "date_registered" => Time.now }
                    l = NGS::Library.create(payload)
                    l.save
                end
            end
        end
        
    end

end
