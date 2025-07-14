# see: https://medium.com/@nicopasquariello/create-a-simple-database-using-active-record-and-sinatra-e21a4e1ef0ce

require_relative "./config/environment"

# Allow CORS (Cross-Origin Resource Sharing) requests
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :delete, :put, :patch, :options, :head]
  end
end

# Parse JSON from the request body into the params hash
use Rack::JSONBodyParser

# Our application
run NGS