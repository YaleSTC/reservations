# frozen_string_literal: true

include AutomaticSeed
include PromptedSeed

# rubocop:disable Rails/Output

# RESET PUBLIC DIR IF WE'VE RESET THE DATABASE
if EquipmentModel.all.empty?
  location_models = Rails.root.to_s + '/public/attachments/equipment_models'
  if File.directory?(location_models) # if the directory exists
    FileUtils.rm_r location_models # delete it and everything inside
  end
end

# GLOBAL VARIABLES
MANUAL = ENV['manual'].present? || ENV['friendly'].present?
NO_PICS = ENV['no_pics'].present? || !MANUAL
IMAGES = Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*'))

# run script
MANUAL ? prompted_seed : automatic_seed

puts 'Successfully completed initialization process!'
