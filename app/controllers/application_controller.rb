require 'sinatra/base'

def is_skippable(name)

    answer = false
    if name.include?("Undetermin")
        return true
    elsif name.include?("NegCtr")
        return true
    elsif name.include?("NegKont")
        return true
    elsif name.include?("Neg-Ktr")
        return true
    end

    return answer

end

class NGS < Sinatra::Base

    color_by_status = { "completed" => "lightgreen", "created" => "lightgray", "submitted" => "LightSteelBlue", "failed" => "Salmon", "running" => "Moccasin", "unknown" => "white", "pending" => "LightSteelBlue"} 

    enable :sessions

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
        @color_by_status = color_by_status
        @runs = NGS::Run.all.reverse
        @pipelines = NGS::Pipeline.where(runlevel: true)
        @success_message = session[:success_message]
        session[:success_message] = nil
        erb :dashboard
    end

    get '/dashboard/jobs' do
        @color_by_status = color_by_status
        @jobs = NGS::Job.all.reverse
        erb :jobs
    end
    get '/dashboard/jobs/:id' do |id|
        @color_by_status = color_by_status
        @job = NGS::Job.find(id)
        erb :job
    end

    get '/dashboard/runs/:id/libraries' do |id|
        @run = NGS::Run.find(id)
        @libraries = @run.libraries
        @pipelines = NGS::Pipeline.where(runlevel: false)
        @success_message = session[:success_message]
        session[:success_message] = nil

        erb :libraries
    end

    get '/dashboard/runs/:id' do |id|
        @color_by_status = color_by_status
        @run = NGS::Run.find(id)
        erb :run
    end

    get '/dashboard/test/:id' do |id|
        @color_by_status = color_by_status
        @run = NGS::Run.find(id)
        erb :libraries_test
    end

    get '/test/:id/bla' do |id|
        params["item"].inspect
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
                run.register_libraries
                run.update_description
            end
        end
        if answer.empty?
            session[:success_message] = "No new runs found."
        else
            session[:success_message] = "Successfully added #{answer.length} runs."
        end
        redirect '/dashboard'
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
        @success_message = session[:success_message]
        session[:success_message] = nil
    end
    
    # scans a registered run to see if libraries need to be added
    get '/runs/:id/libraries/register' do |id|
        answer = []
        run = NGS::Run.find(id)
        run.register_libraries
        return run.libraries.to_json
    end

    get '/runs/:id/create_job/:pipeline_id' do 

        run = NGS::Run.find(params["id"])

        if !run
            return { "error" => "Run with id #{params['id']} not found"}
        end

        pipeline = NGS::Pipeline.find(params["pipeline_id"])

        if !pipeline
            return { "error" => "Pipeline with id #{params['pipeline_id']} not found" }
        end

        if !pipeline.runlevel
            return { "error" => "This function may only be used with run level pipelines"}
        end

        if !NGS::Job.where(run_id: run.id, pipeline_id: pipeline.id).empty?
            "This job already exists"  
        end
        # Construct the pipeline call
        if pipeline.name.include?("backup")
            command = "#{pipeline['template']} --platform miseq"
        else
            command = "#{pipeline['template']} -profile #{settings.pipeline_profile} -r #{pipeline.version} --run_name #{run.name} -resume"
        end

        this_date = Time.now.strftime("%d-%m-%Y")

        # Create the run directory
        wpath = "#{settings.pipeline_run_dir}/#{run.name}_#{run.id}/#{pipeline.name}/#{this_date}"
        FileUtils.mkdir_p(wpath)

        command = "#{command} --input #{run.folder}"

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

        if job
            session[:success_message] = "New job created."
        else
            session[:success_message] = "No new job created."
        end

        redirect '/dashboard'

    end

    post '/runs/:id/create_bulk' do |id|

        run = NGS::Run.find(id)
        if !run
            return { "error" => "Run does not exist!"}
        end

        pipeline = NGS::Pipeline.find(params["pipeline"])
        if !pipeline
            return { "error" => "Pipeline not found"}
        end

        if pipeline.runlevel
            return { "error" => "This function may not be used with run-level pipelines"}
        end

        if !NGS::Job.where(run_id: run.id, pipeline_id: pipeline.id).empty?
            return "This job already exists"  
        end

        libraries = params["libs"].map {|lid| NGS::Library.find(lid) }
        if libraries.empty?
            return { "error" => "No libraries found"}
        end  

        # Construct pipeline call
        command = "#{pipeline['template']} -profile #{settings.pipeline_profile} -r #{pipeline.version} --run_name #{run.name} -resume"

        this_date = Time.now.strftime("%d-%m-%Y")

        # Create the run directory
        wpath = "#{settings.pipeline_run_dir}/#{run.name}_#{run.id}/#{pipeline.name}/#{this_date}"
        FileUtils.mkdir_p(wpath)

        # Make the sample sheet
        rows = [ pipeline.samplesheet_format ]
        libraries.each do |lib|
            if pipeline.samplesheet_format.include?("platform")
                rows << [ lib.name, run.platform.upcase, lib.R1, lib.R2 ].join("\t")
            else
                rows << [ lib.name, lib.R1, lib.R2 ].join("\t")
            end
        end
        ss_name = "#{wpath}/samples.tsv"
        ss = File.new(ss_name, "w+")
        rows.each { |r| ss.puts r }
        ss.close

        command = "#{command} --input samples.tsv"

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

        # link libraries to the job
        libraries.each do |lib|
            xref = NGS::XrefLibrariesJob.create({library_id: lib.id, job_id: job.id})
        end

        if job
            session[:success_message] = "New job created."
        else
            session[:success_message] = "No new job created."
        end

        redirect "/dashboard/runs/#{id}/libraries"

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

    get '/libraries/:id/deactivate' do |id|
        lib = NGS::Library.find(id)
        if lib
            lib.active = false
            lib.save
        end
        redirect "/dashboard/runs/#{lib.run.id}/libraries"
    end
    get '/libraries/:id/activate' do |id|
        lib = NGS::Library.find(id)
        if lib
            lib.active = true
            lib.save
        end
        redirect "/dashboard/runs/#{lib.run.id}/libraries"
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

    get '/pipelines/:id/delete' do |id|
        pipe = NGS::Pipeline.find(id)
        if pipe
            pipe.jobs.each do |job|
                job.remove
            end
            pipe.destroy
            "Pipeline deleted!"
        else
            "Pipeline not found, nothing to do."
        end
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
    
    get '/jobs/:id/libraries' do |id|
        @job = NGS::Job.find(id)
        @run = @job.run
        @libraries = @job.libraries
        erb :job
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

    post '/jobs/:id/update/log' do |id|
        job = NGS::Job.find(id)
        if job
            job.update({"log" => params }.to_json)
        else
            { "error" => "Job does not exist." }
        end
    end

    get '/jobs/:id/delete' do |id|
        job = NGS::Job.find(id)
        if job
            job.remove
            return "Job deleted"
        else
            return "Job with id #{id} not found."
        end
    end

    get '/jobs/delete' do
        NGS::Job.all.each do |job|
            job.delete
        end
        "All jobs deleted"
    end
end