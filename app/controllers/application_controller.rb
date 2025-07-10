require 'sinatra/base'

class NGS < Sinatra::Base

    configure do
        set :illumina_run_dir, '/work_syn/ngs/runs/miseq'
        set :pipeline_run_dir, '/work_syn/ngs/analyses'
        set :pipeline_profile, 'lsh'
    end
    
    not_found do
        content_type :json
 
        { status: 404, message: "Nothing Found!" }.to_json
    end

    get '/' do 
        "LSH NGS Automatisierung"
    end

    get '/dashboard' do
        @runs = NGS::Run.all.reverse
        @pipelines = NGS::Pipeline.all
        erb :runs
    end

    get '/dashboard/jobs' do
        @jobs = NGS::Job.all.reverse
        erb :jobs
    end

    get '/dashboard/runs/:id/libraries' do |id|
        @run = NGS::Run.find(id)
        @libraries = @run.libraries
        erb :libraries
    end

    get '/runs' do 
        NGS::Run.all.to_json
    end

    get '/runs/register' do
        answer = [] # A list of all the newly added directories, if any
        dirs = Dir["#{settings.illumina_run_dir}/*"].select{|f| File.directory?(f) }
        dirs.each do |dir|
            # If this run directory has not been added to the database, do it now. 
            run = NGS::Run.find_by_folder(dir)
            if !run
                name = dir.split("/")[-1]
                run = NGS::Run.create({ "folder" => dir, "platform" => "Illumina", "date_registered" => Time.now, "name" => name })
                run.save
                answer << run
            end
        end
        return answer.to_json
    end
    
    get '/runs/:id/delete' do |id|
        run = NGS::Run.find(id)
        run.destroy
        "Run deleted"
    end

    get '/runs/:id' do |id|
        NGS::Run.find(id).to_json
    end

    get '/runs/:id/libraries' do |id|
        NGS::Library.where(run_id: id).to_json
    end
    
    # scans a registered run to see if libraries need to be added
    get '/runs/:id/libraries/register' do |id|
        answer = []
        run = NGS::Run.find(id)
        # check if the requested run exists
        if run
            # group by library
            data = Dir["#{run['folder']}/**/*.fastq.gz"].group_by{|f| File.basename(f).split(/_L00[0-9]_R[1,2]/)[0]}
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
                    if NGS::Library.where(R1: fwd, run_id: run.id, lane: lane).empty?
                        payload = { "run_id" => run.id, "name" => lib, "R1" => fwd, "R2" => rev, "lane" => lane , "date_registered" => Time.now }
                        l = NGS::Library.create(payload)
                        l.save
                        answer << l
                    end
                end
            end
        end
        return answer.to_json
    end

    get '/runs/:id/create_job/:pipeline_id' do 

        run = NGS::Run.find(params["id"])

        if !run
            { "error" => "Run with id #{params['id']} not found"}
        end

        pipeline = NGS::Pipeline.find(params["pipeline_id"])

        if !pipeline
            { "error" => "Pipeline with id #{params['pipeline_id']} not found" }
        end

        if !NGS::Job.where(run_id: run.id, pipeline_id: pipeline.id).empty?
            return "This job already exists"
        end
        # Construct the pipeline call
        command = "#{pipeline['template']} -profile #{settings.pipeline_profile} -r #{pipeline.version} --run_name #{run.name}"

        this_date = Time.now.strftime("%d-%m-%Y")

        # Create the run directory
        wpath = "#{settings.pipeline_run_dir}/#{run.name}_#{run.id}/#{pipeline.name}/#{this_date}"
        FileUtils.mkdir_p(wpath)

        if pipeline.samplesheet_format
            # Make the samplesheet
            rows = [ pipeline.samplesheet_format ]
            run.libraries.each do |lib|
                next if lib.name.include?("Undetermined") or lib.name.include?("NegCtrl")
                rows << [ lib.name, "ILLUMINA", lib.R1, lib.R2 ].join("\t")
            end
            ss_name = "#{wpath}/samples.tsv"
            ss = File.new(ss_name, "w+")
            rows.each { |r| ss.puts r }
            ss.close
            command = "#{command} --input samples.tsv"
        else # the folder itself is the input
            command = "#{command} --input #{run.folder}"
        end

        payload = { 
            "name" => "#{run.name}_#{pipeline.name}_#{this_date}", 
            "command" => command, 
            "run_dir" => wpath,
            "status" => "created",
            "date_registered" => this_date,
            "run_id" => run.id, 
            "pipeline_id" => pipeline.id 
        }
    
        job = NGS::Job.create(payload)
        job.save

        return job.to_json

    end

    get '/libraries' do
       NGS::Library.all.to_json
    end

    get '/libraries/delete' do
        NGS::Library.all.each do |lib|
            lib.delete
        end
        "All libraries deleted."
    end

    get '/libraries/:id/delete' do |id|
        lib = NGS::Library.find(id)
        if lib
            lib.destroy
            "Library #{id} deleted"
        else
            "Library #{id} not found, nothing to do"
        end
    end

    get '/pipelines' do
        return NGS::Pipeline.all.to_json
    end

    post '/pipelines/new' do    
        if !NGS::Pipeline.find_by_name(params["name"])
            pipe = NGS::Pipeline.create(params)
            return pipe.to_json
        end
        { "error" => "Pipeline already exists" }.to_json
    end

    get '/pipelines/delete' do
        NGS::Pipeline.all.each do |pipe|
            pipe.delete
        end
        "All pipelines deleted"
    end

    get '/jobs' do
        NGS::Job.all.to_json
    end

    post '/jobs/new' do
        j = NGS::Job.create(params)
        j.date_registered = Time.now
        j.save
        return j.to_json
    end

    get '/jobs/:id' do |id|
        job = NGS::Job.find(id)
        if job
            return job.to_json
        else
            "Job with id #{id} not found."
        end
    end

    post '/jobs/:id/update' do |id|
        job = NGS::Job.find(id)
        if job
            job.update(params)
            return job.to_json
        else
            { "error" => "Job does not exist." }
        end
    end

    get '/jobs/:id/delete' do |id|
        job = NGS::Job.find(id)
        if job
            FileUtils.rm_rf(job.run_dir)
            job.destroy
            "Job deleted"
        else
            "Job with id #{id} not found."
        end
    end

    get '/jobs/delete' do
        NGS::Job.all.each do |job|
            job.delete
        end
        "All jobs deleted"
    end
end