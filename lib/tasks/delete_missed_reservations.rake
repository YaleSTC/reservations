desc 'Delete missed reservations'
task delete_missed_reservations: :environment do
  # remove all missed reservations older than the current day
  # do not delete if appconfig isn't set up or if
  # res exp date is not set
  unless AppConfig.first.blank? || AppConfig.first.res_exp_time.blank?
    time = AppConfig.first.res_exp_time
    missed_reservations = Reservation.where(
      'due_date < ?', Time.zone.today - time.days).untouched
    Rails.logger.info "Found #{missed_reservations.size} reservations"

    missed_reservations.each do |missed_reservation|
      Rails.logger.info "Deleting reservation:\n #{missed_reservation.inspect}"
      missed_reservation.destroy
    end

    Rails.logger.info 'Finished processing missed reservations.'
  end
end
