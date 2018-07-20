# frozen_string_literal: true

class DailyTasksJob < ApplicationJob
  queue_as :default

  def perform
    FlagOverdueJob.perform_now
    FlagMissedJob.perform_now
    DenyMissedRequestsJob.perform_now
    EmailCheckinReminderJob.perform_now
    EmailCheckoutReminderJob.perform_now
    EmailMissedReservationsJob.perform_now
    EmailOverdueReminderJob.perform_now
    DeleteOldBlackoutsJob.perform_now
    DeleteMissedReservationsJob.perform_now
  end
end
