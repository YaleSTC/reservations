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
