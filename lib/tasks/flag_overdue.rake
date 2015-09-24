desc 'Flag reservations due in the past as overdue'
task flag_overdue: :environment do
  new_overdue = Reservation.where('due_date <= ?',
                                  Time.zone.today - 1.day).checked_out
  Rails.logger.info "Found #{new_overdue.size} newly overdue reservations"

  new_overdue.each do |overdue_reservation|
    Rails.logger.info "Flagging reservation #{overdue_reservation.id} as "\
      'overdue'
    overdue_reservation.update_attributes(overdue: true)
  end
end
