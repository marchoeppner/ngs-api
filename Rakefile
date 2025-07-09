require_relative "./config/environment"
require "sinatra/activerecord/rake"

#Description of task
desc "Start the console"

#Code to execute
task :console do
  #Allows the SQL code to be displayed
  ActiveRecord::Base.logger = Logger.new(STDOUT)

  #Starts a new Pry session in the console
  Pry.start
end

#Description of task
desc "Start the server"

#Code to execute
task :server do 
   #Checking to see if all migrations are complete
  if ActiveRecord::Base.connection.migration_context.needs_migration?
    puts "Migrations are pending. Make sure to run `rake db:migrate` first."
    return
  end

  # rackup -p PORT will run on the port specified (9292 by default)
  ENV["PORT"] ||= "9292"
  rackup = "rackup -p #{ENV['PORT']}"

  # rerun allows auto-reloading of server when files are updated
  # -b runs in the background (include it or binding.pry won't work)
  exec "bundle exec rerun -b '#{rackup}'"
end