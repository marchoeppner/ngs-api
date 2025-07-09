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

module Slurm

    class Job
        
        attr_accessor :file, :meta

        def initialize(sfile)
            @file = sfile
            @meta = {}
            @job_id = null
        end

    end
end

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
        "#SBATCH -J #{job['name']}",
        "#SBATCH --nodes=1",
        "#SBATCH --time=10:00:00",
        "#SBATCH --mem=4000",
        "#SBATCH --ntasks=1",
        "#SBATCH -e slurm.err",
        "#SBATCH --cpus-per-task=1"
    ]

    s = File.new("sbatch.sh", "w+")
    sbatch_boilerplate.each {|l| s.puts l }
    s.puts command

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.on("-l","--list","Get list of runs") {|argument| options.list = argument }
opts.on("-r","--register","Register runs and libraries") {|argument| options.register = argument }
opts.on("-i","--id","=ID", "Get run by id") {|argument| options.id = argument }
opts.on("-p","--pipeline","=PIPELINE", "Pipeline to use") {|argument| options.pipeline = argument }
opts.on("-o","--outfile", "=OUTFILE","Output file") {|argument| options.outfile = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

$server	= 'http://localhost:9292'

pipeline_profile = "lsh"

jobs = rest_get("jobs")

jobs.each do |job|

    if job["status"] == "created"
        warn "Found a new job (#{job['name']})"
        Dir.chdir(job["run_dir"]) do |dir|
            build_slurm_script(job)
        end
        # submitting job
        payload = { "attempts" => 1 }
        rest_post("jobs/#{job['id']}/update", payload)
    elsif job["status"] == "complete"
        # do nothing

    elsif job["status"] == "failed"
        if job["attempts"] < 3
            # Re-submit
            attempts = job["attempts"].to_i+1
            payload = { "attempts" =>  attempts }
            rest_post("jobs/#{job['id']}/update", payload)
        end
    end
end