require 'rake'

namespace :app do
	desc 'a rake task to set up the initial admin and configuration for reservations site'
  task clear_import: :environment do
  	Category.where("name = ?", 'DSLRs').first.destroy(:force)
  	Category.where("name = ?", 'Power Cables').first.destroy(:force)
  	Category.where("name = ?", 'Tripodss').first.destroy(:force)
  	puts "clear!"
  end
end