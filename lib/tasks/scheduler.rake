# Tasks for Heroku scheduler (https://devcenter.heroku.com/articles/scheduler)
# Modeled off of config/schedule.rb (whenever gem), any changes there should be
# implemented here

desc 'Heroku scheduler tasks'
task run_daily_tasks: :environment do
  puts 'Running daily tasks (e-mails, cleanup, etc)...'
  Rake::Task['send_upcoming_checkin_reminder'].invoke
  Rake::Task['send_overdue_checkin_reminder'].invoke
  Rake::Task['email_missed_reservations'].invoke
  Rake::Task['delete_missed_reservations'].invoke
  Rake::Task['deny_missed_requests'].invoke
  Rake::Task['email_checkout_reminder'].invoke
  Rake::Task['delete_old_blackouts'].invoke
  puts 'Done!'
end

task run_hourly_tasks: :environment do
  puts 'Running hourly tasks (notes e-mail)...'
  Rake::Task['send_reservation_notes'].invoke
  puts 'Done!'
end
