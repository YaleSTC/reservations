# frozen_string_literal: true

# rubocop:disable Rails/Output
module AutomaticSeed
  def automatic_seed
    start_time = Time.zone.now
    puts 'Seeding the database automatically, without images...'
    Generator.app_config
    create_superuser
    Generator.generate('user', 25)
    Generator.generate('category', 10)
    Generator.generate('equipment_model', 25)
    Generator.generate('equipment_item', 50)
    Generator.generate('checkin_procedure', 3)
    Generator.generate('checkout_procedure', 3)
    generate_all_reservation_types
    Generator.generate('reservation', 3)
    puts "Successfully seeded all records! (#{Time.zone.now - start_time}s)\n\n"

    return if ENV['CAS_AUTH'].present?
    puts "You can log in using e-mail 'email@email.com' and "\
         "password 'passw0rd'"
  end

  private

  def generate_all_reservation_types
    puts 'Generating reservations at each point in the lifecycle'
    Generator.all_reservation_types
  end

  def create_superuser
    u = Generator.superuser
    if ENV['CAS_AUTH'].present?
      prompt_field(u, :cas_login)
      u.username = u.cas_login
    else
      u.username = u.email
      u.password = 'passw0rd'
      u.password_confirmation = u.password
    end
    u.save
  end
end
