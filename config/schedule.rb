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

# stagger jobs by offsetting with current time
time = Time.zone.now

# define cron strings
nightly_cron_str = time.min.to_s + ' 5 * * *'
hourly_cron_str = time.min.to_s + ' * * * *'

# every night around 5 AM
every nightly_cron_str do
  rake 'run_daily_tasks'
end

# every hour (except five AM)
every hourly_cron_str do
  rake 'run_hourly_tasks'
end
