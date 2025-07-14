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

def create_run_dir(run, wd)

    wpath = "#{wd}/#{run['id']}"
    
    FileUtils.mkdir_p(wpath)

    return wpath
end

def build_samplesheet(run, pipeline, run_dir)

    rows = [ pipeline["samplesheet_format"] ]

    libs = rest_get("runs/#{run['id']}/libraries")
    libs.each do |lib|
        rows << [ lib["name"], "ILLUMINA", lib["R1"], lib["R2"]].join("\t")
    end

    ss_name = "#{run_dir}/samples.tsv"
    ss = File.new(ss_name, "w+")
    rows.each { |r| ss.puts r }
    ss.close

    return ss_name

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

work_dir = "/mnt/share/volume1/work/ngs/run_dir"

pipeline_profile = "lsh"

valid_pipelines = rest_get("pipelines")

if options.list
    runs = rest_get("runs")
    
    runs.each do |run|
        libraries = rest_get("runs/#{run['id']}/libraries")
        puts "#{run['folder']} [#{run['id']}]\t#{libraries.length} Libraries"
    end
elsif options.register
    reg_run = rest_get("runs/register")
    puts "#{reg_run.length} new runs registered"
    puts "-------------------------------------"
    reg_run.each do |run|
        puts "Run: #{run['folder']} [#{run['id']}]"
        reg_lib = rest_get("runs/#{run['id']}/libraries/register")
        reg_lib.each do |lib|
            puts "\tAdded library #{lib['name']}/#{lib['lane']}"
        end
    end
elsif options.id && options.pipeline

    run = rest_get("runs/#{options.id}")
    if !run
        abort "No run found with id #{options.id}"
    end

    # Get the pipeline specs from the database
    pipeline = valid_pipelines.find{|pipe| pipe["name"] == options.pipeline }

    if !pipeline
        abort "Pipeline #{options.pipeline} not configured, exiting."
    end

   job = rest_get("runs/#{run['id']}/create_job/#{pipeline['id']}")
   puts job.inspect
end