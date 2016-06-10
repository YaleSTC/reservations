# frozen_string_literal: true
module EmailJobHelper
  private

  def send_email(res)
    UserMailer.reservation_status_update(res).deliver_now
  end

  def log_email(res)
    Rails.logger.info "Sending reminder for #{res.human_status} reservation:\n \
    #{res.inspect}"
  end
end
