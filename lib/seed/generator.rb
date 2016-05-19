# frozen_string_literal: true
# rubocop:disable Rails/Output
module Generator
  require 'ffaker'
  require 'ruby-progressbar'

  PROGRESS_STR = '%t: [%B] %P%% | %c / %C | %E'

  def self.generate(obj, n)
    return if n == 0
    puts "Generating #{n} #{obj.camelize}...\n"
    progress = ProgressBar.create(format: PROGRESS_STR, total: n)
    n.times do
      send(obj)
      progress.increment
    end
  end

  def self.all_reservation_types
    ReservationGenerator.generate_all_types
  end

  def self.app_config
    AppConfigGenerator.generate
  end

  def self.blackout
    BlackoutGenerator.generate
  end

  def self.category
    CategoryGenerator.generate
  end

  def self.checkin_procedure
    ProcedureGenerator.generate_checkin
  end

  def self.checkout_procedure
    ProcedureGenerator.generate_checkout
  end

  def self.equipment_model
    EquipmentModelGenerator.generate
  end

  def self.equipment_item
    EquipmentItemGenerator.generate
  end

  def self.requirement
    RequirementGenerator.generate
  end

  def self.reservation
    ReservationGenerator.generate_random
  end

  def self.user
    UserGenerator.generate
  end

  def self.superuser
    UserGenerator.generate_superuser
  end
end
