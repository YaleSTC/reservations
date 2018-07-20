# frozen_string_literal: true

class HourlyTasksJob < ApplicationJob
  queue_as :default

  def perform
    EmailNotesToAdminsJob.perform_now
  end
end
