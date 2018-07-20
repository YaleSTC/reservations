# frozen_string_literal: true

require 'spec_helper'

describe DailyTasksJob, type: :job do
  shared_examples 'enqueues' do |job|
    it "the #{job}" do
      expect(job).to receive(:perform_now)
      described_class.perform_now
    end
  end
  JOBS = [FlagOverdueJob, FlagMissedJob, DenyMissedRequestsJob,
          EmailCheckinReminderJob, EmailCheckoutReminderJob,
          EmailMissedReservationsJob, EmailOverdueReminderJob,
          DeleteOldBlackoutsJob, DeleteMissedReservationsJob].freeze
  JOBS.each { |job| it_behaves_like 'enqueues', job }
end
