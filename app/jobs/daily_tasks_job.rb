# frozen_string_literal: true
class DailyTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    FlagOverdueJob.perform_later
    FlagMissedJob.perform_later
    DenyMissedRequestsJob.perform_later
    EmailCheckinReminderJob.perform_later
    EmailCheckoutReminderJob.perform_later
    EmailMissedReservationsJob.perform_later
    EmailOverdueReminderJob.perform_later
    DeleteOldBlackoutsJob.perform_later
    DeleteMissedReservationsJob.perform_later
  end
end
