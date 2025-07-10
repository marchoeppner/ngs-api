#!/usr/bin/env ruby
# == NAME
# ngs_api.rb
#
# == AUTHOR
#  Marc Hoeppner, mphoeppner@gmail.com

require 'optparse'
require 'ostruct'
require 'rest_client'
require 'json'
require 'fileutils'


def rest_get(url)
	
    $request_counter ||= 0   # Initialise if unset  
    $last_request_time ||= 0 # Initialise if unset

    # Rate limiting: Sleep for the remainder of a second since the last request on every third request
    $request_counter += 1
    if $request_counter == 15 
    diff = Time.now - $last_request_time
    sleep(1-diff) if diff < 1
    $request_counter = 0
    end

    begin
        response = RestClient.get "#{$server}/#{url}", {:accept => :json}

        $last_request_time = Time.now
        JSON.parse(response)
    rescue RestClient::Exception => e
        puts "Failed for #{url}! #{response ? "Status code: #{response}. " : ''}Reason: #{e.message}"

        # Sleep for specified number of seconds if there is a Retry-After header
        if e.response.headers[:retry_after]
            sleep(e.response.headers[:retry_after].to_f)
            retry # This retries from the start of the begin block
        else
            abort("Quitting... #{e.inspect}")
        end
    end
end

def rest_post(url, payload)
	
    $request_counter ||= 0   # Initialise if unset  
    $last_request_time ||= 0 # Initialise if unset

    # Rate limiting: Sleep for the remainder of a second since the last request on every third request
    $request_counter += 1
    if $request_counter == 15 
    diff = Time.now - $last_request_time
    sleep(1-diff) if diff < 1
    $request_counter = 0
    end

    begin
        response = RestClient.post "#{$server}/#{url}", payload, {:accept => :json}

        $last_request_time = Time.now
        JSON.parse(response)
    rescue RestClient::Exception => e
        puts "Failed for #{url}! #{response ? "Status code: #{response}. " : ''}Reason: #{e.message}"

        # Sleep for specified number of seconds if there is a Retry-After header
        if e.response.headers[:retry_after]
            sleep(e.response.headers[:retry_after].to_f)
            retry # This retries from the start of the begin block
        else
            abort("Quitting... #{e.inspect}")
        end
    end
end

def build_slurm_script(job)

    command = job["command"]
    sbatch_boilerplate = [
        "#!/bin/bash",
        "#SBATCH -J #{job['name']}",
        "#SBATCH --nodes=1",
        "#SBATCH --time=10:00:00",
        "#SBATCH --mem=4000",
        "#SBATCH --ntasks=1",
        "#SBATCH -e slurm.err",
        "#SBATCH --cpus-per-task=1"
    ]

    s = File.new("slurm.sh", "w+")
    sbatch_boilerplate.each {|l| s.puts l }
    s.puts command
    s.close

    return "slurm.sh"

end

def submit_job(file)

    slurm_id = `sbatch #{file}`.slice(/\d+/)
    return slurm_id.to_i

end

def get_status(slurm_id)

    status = `scontrol show job #{slurm_id}`
    
    if status == ""
        return "unkown"
    else
        job_state = status.slice(/JobState=[A-Z]*/).split("=")[-1].downcase
        return job_state
    end

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

$server	= 'http://localhost:9292'

pipeline_profile = "lsh"

jobs = rest_get("jobs")

this_date = Time.now.strftime("%d-%m-%Y")

jobs.each do |job|

    # a new job, needs to be submitted
    if job["status"] == "created"
        warn "Found a new job (#{job['name']}), submitting..."
        job_id = nil
        Dir.chdir(job["run_dir"]) do |dir|
            file = build_slurm_script(job)
            job_id = submit_job(file)
        end  
        payload = { "attempts" => 1 , "status" => "submitted", "slurm_id" => job_id }
        rest_post("jobs/#{job['id']}/update", payload)
    # a submitted job, check status
    elsif [ "running", "pending", "submitted" ].include?(job["status"])
        warn "Active job #{job['slurm_id']}, updating status..."
        status = get_status(job["slurm_id"])
        payload = { "status" => status, "date_updated" => this_date}
        rest_post("jobs/#{job['id']}/update", payload)
    # job failed, check if it can be re-submitted 
    elsif job["status"] == "failed"
        warn "Failed job #{job['slurm_id']}..."
        if job["attempts"] < 3
            warn "\tResubmitting!"
            job_id = nil
            Dir.chdir(job["run_dir"]) do |dir|
                job_id = submit_job("slurm.sh")
            end  
            attempts = job["attempts"].to_i+1
            payload = { "slurm_id" => job_id, "attempts" => attempts, "status" => "submitted", "date_updated" => this_date }
            rest_post("jobs/#{job['id']}/update", payload)
        end
    elsif job["status"] == "completed"
        # remove the work directory
        wd = "#{job['run_dir']}/work"
        if File.directory?(wd)
            system("rm -Rf #{wd}")
        end
    end
end

