class UserMailer < ActionMailer::Base
  # Workaround so that RSpec start-up doesn't fail.
  # TODO: Have RSpec initialize AppConfig with configuration.
  add_template_helper(ApplicationHelper)
  if AppConfig.first.nil?
    default from: 'no-reply@reservations.app'
  else
    default from: AppConfig.get(:admin_email), cc: AppConfig.get(:admin_email)
  end

  # checks the status of the current reservation and sends the appropriate email
  # receipt forces a check out receipt to be sent
  def reservation_status_update(reservation, receipt = false) # rubocop:disable all
    set_app_config

    @reservation = reservation
    @status = @reservation.status

    return if !receipt && @status == 'returned overdue' &&
              @reservation.equipment_model.late_fee == 0

    return if receipt && @reservation.checked_out.nil?

    if @reservation.start_date == Time.zone.today &&
       @status == 'reserved'
      @status = 'starts today'
    elsif @reservation.due_date == Time.zone.today &&
          @status == 'checked out'
      @status = 'due today'
    end

    if receipt && (@status == 'due today' || @status == 'overdue')
      # force sending a check out receipt
      @status = 'checked out'
    end

    status_formatted = @status.split.map(&:capitalize) * ' '

    mail(to: @reservation.reserver.email,
         subject: '[Reservations] ' \
                  "#{@reservation.equipment_model.name.capitalize} "\
                  " #{status_formatted}")
  end

  private

  def set_app_config
    @app_configs ||= AppConfig.first
  end
end
