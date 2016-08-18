# frozen_string_literal: true
class EmailNotesToAdminsJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info "Found #{checked_out.size} reservations checked out "\
      "with notes and #{checked_in.size} reservations checked in with notes."
    unless no_notes
      Rails.logger.info 'Sending a reminder email...'
      run
    end
    clean
    Rails.logger.info 'Done!'
  end

  private

  def checked_out
    @out ||= Reservation.checked_out.notes_unsent
  end

  def checked_in
    @in ||= Reservation.returned.notes_unsent
  end

  def no_notes
    checked_out.empty? && checked_in.empty?
  end

  def run
    AdminMailer.notes_reservation_notification(checked_out, checked_in)
               .deliver_now
    update
  end

  def update
    # reset notes_unsent flag on all reservations
    checked_out.update_all(notes_unsent: false)
    checked_in.update_all(notes_unsent: false)
  end

  def clean
    @in = nil
    @out = nil
  end
end
