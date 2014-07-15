# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

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

every 1.day, :at => '5:00 am' do
  rake "send_upcoming_checkin_reminder"
  rake "send_overdue_checkin_reminder"
  rake "delete_missed_reservations"
  rake "deny_missed_requests"
  rake "delete_old_blackouts"
end

every 1.hour do
  rake "send_reservation_notes"
end

