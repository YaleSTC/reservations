desc 'Mark missed requests as denied'
task deny_missed_requests: :environment do
  # get all requests that began yesterday and weren't approved / denied /
  # acted upon
  # also sends an email to the user
  missed_requests = Reservation.missed_requests
  Rails.logger.info "Found #{missed_requests.size} missed requests."

  missed_requests.each do |request|
    Rails.logger.info "Marking as denied:\n #{request.inspect}"
    request.status = 'denied'
    request.flag(:expired)
    request.save!
    UserMailer.reservation_status_update(request).deliver_now
  end

  Rails.logger.info 'Finished processing missed requests.'
end
