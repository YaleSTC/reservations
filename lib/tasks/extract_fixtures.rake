require 'yaml'

class Hash
  # Original function is in /usr/lib/ruby/1.8/yaml/rubytypes.rb
  # Replacing the to_yaml function so it'll serialize hashes sorted (by their keys)
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|   # <-- here's my addition (the 'sort')
          map.add( k, v )
        end
      end
    end
  end
end

#now the RAKE part
desc 'Create YAML test fixtures from data in an existing database.
Defaults to development database. Set RAILS_ENV to override.'

task :extract_fixtures => :environment do
  sql = "SELECT * FROM %s"
  skip_tables = ["schema_info", "sessions", "schema_migrations"]
  ActiveRecord::Base.establish_connection
  tables = ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : ActiveRecord::Base.connection.tables - skip_tables
  Dir.mkdir("#{Rails.root}/preload_data/") unless File::exists?("#{Rails.root}/preload_data/")
  tables.each do |table_name|
    i = "000"
    File.open("#{Rails.root}/preload_data/#{table_name}.yml", 'w') do |file|
      data = ActiveRecord::Base.connection.select_all(sql % table_name)
      file.write data.inject({}) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml
    end
  end
end

