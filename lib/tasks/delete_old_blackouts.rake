desc 'Delete old blackouts'
task delete_old_blackouts: :environment do
  # remove all blackouts older than the current day
  # do not delete if appconfig isn't set up or if
  # blackout exp date is not set
  return if AppConfig.blank? || AppConfig.first.blackout_exp_time.blank?
  time = AppConfig.first.blackout_exp_time
  old_blackouts = Blackout.where('end_date < ?', Date.current - time.day)
  old_blackouts.each do |b|
    Rails.logger.info "Deleting old blackout:\n #{b.inspect}"
    b.destroy
  end
  Rails.logger.info 'Finished deleting old blackouts.'
end
