# Manual

This manual is based on [this](https://medium.com/@nicopasquariello/create-a-simple-database-using-active-record-and-sinatra-e21a4e1ef0ce) article. 

## Overview

This API was developed to provide a database backend for NGS data handling and processing. It can register new sequencing runs and parse library information for each run. It can additionally store information about processing tasks, to be used in combination with some kind of cron job or similar to execute and track processing tasks.

## Usage

### Running the server

Requires ruby >= 3.4.0 and a recent version of bundler

- Clone code to desired location
- Install libraries
```bash
bundle install
```

Assuming this throws no errors, launch the server:

```bash
rake server
```

You may wish to customize the following things:

#### Customization

API Port: This is defined via the Rakefile or an ENV variable 'PORT' 

`export PORT=1234`

Location of your Illumina runs: This is defined in app/controllers/application_controller

```ruby
configure do
    set :illumina_run_dir, '/mnt/share/volume1/work/ngs/runs'
end
```

### Using the API

The API will be available under the Port configured in `Rakefile` (default: 9292) or set via the PORT environment variable.

```
http://localhost:9292
```

End points are:

| Endpoint | Description |
| -------- | ----------- |
| /runs    | List all runs already registered |
| /runs/register | Scan for new run folders and register |
| /runs/:id | Specify the id of a run to get run information |
| /runs/:id/libraries | List all libraries registered to this run |
| /runs/:id/create_job/:pipeline_id | Takes all libraries of that run and builds a job for a specified pipeline |
| /libraries | List all registered libraries (not recommended for big databases) |
| /libraries/:id | List a specific library by id |
| /pipelines | List all known pipelines |
| /jobs | List all the processing jobs |
| /jobs/new | Add a new processing job |
| /pipelines | List all configured pipelines |


## Development

### Adding a new table

#### Create a migration

```bash
rake db:create_migration NAME=a_migration
```

##### Add a model

Create my_table.rb in app/models

```ruby
class Pipeline < ActiveRecord::Base

end

```

##### Edit the migration

This adds the relevant columns

```ruby
class Amigration < ActiveRecord::Migration[6.1]
  def change
    create_table :pipelines do |t|
      t.string :name
      t.string :description
      t.date :created_at
    end
  end
end

```

The table name is typically the plural of the class name. 

##### Update the migration

If this table already exists, it can also be updated:

```
rake db:create_migration NAME=updatepipeline
```

```ruby
class UpdateMyModel < ActiveRecord::Migration[6.1]
  def change
    add_column :pipelines, :version, :integer
  end
end
```

##### Run migration

```bash
rake db:migration
```


