# frozen_string_literal: true
class DeleteOldBlackoutsJob < ActiveJob::Base
  queue_as :default

  def perform
    return if disabled
    run
    clean
    Rails.logger.info 'Finished deleting old blackouts.'
  end

  private

  def disabled
    AppConfig.check(:blackout_exp_time, '').blank?
  end

  def run
    old_blackouts.each do |b|
      log_deletion b
      b.destroy
    end
  end

  def old_blackouts
    @threshold ||= Time.zone.today - AppConfig.get(:blackout_exp_time).days
    @old ||= Blackout.where('end_date < ?', @threshold)
  end

  def clean
    @threshold = nil
    @old = nil
  end

  def log_deletion(blackout)
    Rails.logger.info "Deleting old blackout:\n #{blackout.inspect}"
  end
end
