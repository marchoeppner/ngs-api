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

$server	= 'http://localhost:9292'

pipelines = {
    "gabi_1.2.0" => { "name" => "gabi_1.2.0", "description" => "GABI - Genomic Analysis of Bacterial Isolates", "version" => "1.2.0", "template" => "nextflow run bio-raum/gabi", "samplesheet_format" => "sample\tplatform\tfq1\tfq2" },
    "foodme2_1.2.0" => { "name" => "foodme2_1.2.0", "description" => "FooDMe2 - Metabarcoding", "version" => "1.2.0", "template" => "nextflow run bio-raum/FooDMe2", "samplesheet_format" => "sample\tfq1\tfq2" }
}

pipelines.each do |pipe,info|
    warn "Processing #{pipe}"

    d = rest_post("pipelines/new", info)
    puts d.inspect

end