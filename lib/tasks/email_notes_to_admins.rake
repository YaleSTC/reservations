desc 'Send email to admins on reservations with notes'
task email_notes_to_admins: :environment do
  # gets all reservations with notes and sends an email to the admin of the
  # application, to alert them.
  notes_reservations_out = Reservation.has_notes.checked_out.notes_unsent
  notes_reservations_in = Reservation.has_notes.checked_in.notes_unsent
  Rails.logger.info "Found #{notes_reservations_out.size} reservations "\
                    "checked out with notes and #{notes_reservations_in.size} "\
                    'reservations checked in with notes.'

  email_notes_to_admins(notes_reservations_out, notes_reservations_in)

  Rails.logger.info 'Done!'
end

def email_notes_to_admins(notes_reservations_out, notes_reservations_in)
  return if notes_reservations_out.empty? && notes_reservations_in.empty?

  Rails.logger.info 'Sending a reminder email...'

  AdminMailer.notes_reservation_notification(notes_reservations_out,
                                             notes_reservations_in).deliver
  # reset notes_unsent flag on all reservations
  notes_reservations_out.update_all(notes_unsent: false)
  notes_reservations_in.update_all(notes_unsent: false)
end
