desc "Delete old blackouts"
task :delete_old_blackouts => :environment do
  #remove all blackouts older than the current day
  old_blackouts = Blackout.where("end_date < ?", Date.today - 1.month)
  old_blackouts.each do |b|
    Rails.logger.info "Deleting old blackout:\n #{b.inspect}"
    b.destroy
  end
  Rails.logger.info "Finished deleting old blackouts."
end
