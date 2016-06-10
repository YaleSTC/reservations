# frozen_string_literal: true
# Tasks for Heroku scheduler (https://devcenter.heroku.com/articles/scheduler)
# Modeled off of config/schedule.rb (whenever gem), any changes there should be
# implemented here

desc 'Heroku scheduler tasks'
task run_daily_tasks: :environment do
  puts 'Running daily tasks (e-mails, cleanup, etc)...'
  DailyTasksJob.perform_now
end

task run_hourly_tasks: :environment do
  puts 'Running hourly tasks (notes e-mail)...'
  HourlyTasksJob.perform_now
end
