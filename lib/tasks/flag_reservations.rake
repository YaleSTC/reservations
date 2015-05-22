namespace :flag_reservations do
  desc 'Flag reservations due yesterday as overdue'
  task flag_overdue: :environment do
    new_overdue = Reservation.where('due_date = ?',
                                    Time.zone.today - 1.day).checked_out
    Rails.logger.info "Found #{new_overdue.size} newly overdue reservations"

    new_overdue.each do |overdue_reservation|
      Rails.logger.info "Flagging reservation #{overdue_reservation.id} as "\
        'overdue'
      overdue_reservation.update_attributes(overdue: true)
    end
  end

  desc 'Flag not checked out reservations starting yesterday as missed'
  task flag_missed: :environment do
    new_missed = Reservation.where(
      'start_date <= ?', Time.zone.today - 1.day).reserved

    Rails.logger.info "Found #{new_missed.size} newly missed reservations"

    new_missed.each do |missed_reservation|
      Rails.logger.info "Flagging reservation #{missed_reservation.id} as "\
        'missed'
      missed_reservation.update_attributes(status: 'missed')
    end
  end

  desc 'Mark missed requests as denied'
  task deny_missed_requests: :environment do
    # get all requests that began yesterday and weren't approved / denied /
    # acted upon
    missed_requests = Reservation.missed_requests
    Rails.logger.info "Found #{missed_requests.size} missed requests."

    missed_requests.each do |request|
      Rails.logger.info "Marking as denied:\n #{request.inspect}"
      request.update_attributes(status: 'denied')
    end

    Rails.logger.info 'Finished processing missed requests.'
  end
end
