desc 'Flag not checked out reservations starting yesterday as missed'
task flag_missed: :environment do
  new_missed =
    Reservation.where('start_date <= ?', Time.zone.today - 1.day).reserved

  Rails.logger.info "Found #{new_missed.size} newly missed reservations"

  new_missed.each do |missed_reservation|
    Rails.logger.info "Flagging reservation #{missed_reservation.id} as "\
      'missed'
    missed_reservation.update_attributes(status: 'missed')
  end
end
