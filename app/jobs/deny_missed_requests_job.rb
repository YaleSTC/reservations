# frozen_string_literal: true
class DenyMissedRequestsJob < ReservationJob
  include EmailJobHelper

  private

  def type
    'missed requests'
  end

  def missed_requests
    collection(:missed_requests)
  end

  def prep_collection
    missed_requests
  end

  def run
    missed_requests.each do |r|
      log_denial r
      r.expire!
      send_email r
    end
  end

  def log_denial(res)
    Rails.logger.info "Marking as denied:\n #{res.inspect}"
  end
end
