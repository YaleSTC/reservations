require 'active_record/fixtures'
desc "Load fixtures to an empty database"
task :load_fixtures => :environment do
  ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
  path = ENV['FIXTURE_DIR'] || "#{RAILS_ROOT}/preload_data"
  Dir.glob("#{path}/*.{yml}").each do |fixture_file|
    Fixtures.create_fixtures(path, File.basename(fixture_file, '.*'))
  end
end

