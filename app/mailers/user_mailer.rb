# frozen_string_literal: true
class UserMailer < ActionMailer::Base
  # Workaround so that RSpec start-up doesn't fail.
  # TODO: Have RSpec initialize AppConfig with configuration.
  add_template_helper(ApplicationHelper)
  if AppConfig.check :admin_email
    default from: AppConfig.get(:admin_email), cc: AppConfig.get(:admin_email)
  else
    default from: 'no-reply@reservations.app'
  end

  # checks the status of the current reservation and sends the appropriate email
  # force overrides and sends the specified email

  VALID_STATUSES = ['checked out', 'denied', 'due today', 'missed', 'overdue',
                    'request approved', 'requested', 'returned',
                    'returned overdue', 'starts today'].freeze

  def reservation_status_update(reservation, force = '') # rubocop:disable all
    if AppConfig.get(:disable_user_emails)
      Rails.logger.warn 'User e-mails disabled in application settings.'
      return
    end
    set_app_config
    @reservation = reservation

    # abort if the override is not valid
    if !force.empty?
      return unless VALID_STATUSES.include?(force)
      return if force == 'checked out' && @reservation.checked_out.nil?
      return if force == 'request approved' && !@reservation.approved?
      @status = force
    else
      @status = @reservation.human_status
    end

    # don't send fee emails if there's no fee
    return if @status == 'returned overdue' &&
              @reservation.equipment_model.late_fee == 0

    if @status == 'reserved'
      # we only send emails for reserved reservations if it was a request
      return unless @reservation.flagged?(:request)
      @status = 'request approved'
    elsif @status == 'denied' &&
          @reservation.flagged?(:expired)
      @status = 'request expired'
    end

    status_formatted = @status.sub('_', ' ').split.map(&:capitalize) * ' '

    mail(to: @reservation.reserver.email,
         subject: '[Reservations] ' \
                  "#{@reservation.equipment_model.name.capitalize} "\
                  "#{status_formatted}")
  end

  private

  def set_app_config
    @app_configs ||= AppConfig.first
  end
end
