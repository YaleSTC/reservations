# frozen_string_literal: true
class ReservationJob < ActiveJob::Base
  queue_as :default
  UNDEFINED_MESSAGE = 'JOB NOT DEFINED'

  def perform
    if enabled
      log_start
      run
      clean
      log_completion
    else
      log_disabled
    end
  end

  private

  def type
    UNDEFINED_MESSAGE
  end

  def task
    self.class.name
  end

  def enabled
    true
  end

  def run
  end

  def prep_collection
  end

  def log_start
    prep_collection
    Rails.logger.info "Found #{collection.count} #{type} reservations."
  end

  def log_disabled
    Rails.logger.info "Reservations is not configured to perform #{task}. "\
      'Please change the application settings if you wish to do so.'
  end

  def log_completion
    Rails.logger.info 'Done!'
  end

  def collection(scope = :all)
    @set ||= Reservation.send(scope)
  end

  def clean
    @set = nil
  end
end
