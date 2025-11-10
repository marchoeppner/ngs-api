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

    def update_description
        if self.platform == "Illumina"
            if File.exist?("#{self.folder}/SampleSheet.csv")
                lines = IO.readlines("#{self.folder}/SampleSheet.csv")
                line = lines.find {|l| l.match(/^Experiment\sName.*/)}
                if line
                    name = line.split(",")[-1].strip
                    self.update({ "description" => name })
                    self.save
                end
            end
        elsif self.platform == "Nanopore"
            json = Dir["#{self.folder}/**/report*.json"].first
            if json
                data = JSON.parse(IO.readlines(json).join("\n"))
                info = data["protocol_run_info"]
                self.update({"description" => info["user_info"]["sample_id"], "name" => info["user_info"]["protocol_group_id"], "kit" => info["meta_info"]["tags"]["kit"]["string_value"]})
                self.save
            end
        end
    end

    def register_libraries

        if self.platform == "Illumina"
            data = Dir["#{self.folder}/**/*.fastq.gz"].group_by{|f| File.basename(f).split(/_L00[0-9]_R[1,2]/)[0]}
            data.each do |lib,reads|
                # group by lane
                reads.group_by{|r| File.basename(r).slice(/L0[0-9]*/) }.each do |b,fastqs|
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
        elsif self.platform == "Nanopore"
            data = Dir["#{self.folder}/**/fastq/*.fastq.gz"].group_by{|f| File.basename(f)}
            data.each do |lib,reads|
                fwd = reads[0]
                lane = "1"         
                 if NGS::Library.where(R1: fwd, run_id: self.id, lane: lane).empty?
                    payload = { "run_id" => self.id, "name" => lib, "R1" => fwd, "lane" => lane , "date_registered" => Time.now }
                    l = NGS::Library.create(payload)
                    l.save
                end
            end
        end
        
    end

end
