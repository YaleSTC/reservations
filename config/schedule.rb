# frozen_string_literal: true
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# For Heroku deployments, this will be superseded by the Heroku scheduler (for
# more info see: https://devcenter.heroku.com/articles/scheduler).
# Any changes here should be implemented in lib/tasks/scheduler.rake!

# Example:
#
# set :cron_log, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Add all set environment variables to Crontab
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

# Log to stdout
set :output, "/var/log/cron.log"

# Overwrite rake job_type to not include --silent flag
job_type :rake,    "cd :path && :environment_variable=:environment bundle exec rake :task :output"

# Set environment
set :environment, ENV["RAILS_ENV"]

# every night around 5 AM EST
every :day, at: '12:00am' do
  rake 'run_daily_tasks'
end

# every hour (except five AM)
every :hour do
  rake 'run_hourly_tasks'
end
