# This script is used to populate the database with preload data. 
# It does not clear the database - mainly because that would mean deleting your admin login.
# All the numbers are pretty arbitrary, and can be changed to suit your needs, and how many records you want.
# As it stands, you'll need to follow the format and create a new seed generation block for each
# model you want to seed in the database, every time you create a model that isn't already here.
# Order matters!! The script will fail if certain records (Catgeories, EquipmentModels) aren't
# generated first and in the order listed.

require 'ffaker'


#-------METHODS

#Method for prompting the user for the number of records per model they want to seed into the database.
def ask_for_records( model )
  STDOUT.puts "\nHow many #{model} records would you like to generate? (please enter a number)"
  STDIN.gets.chomp.to_i
end

def time_rand from = 0.0, to = Time.now
  Time.at(from + rand * (to.to_f - from.to_f))
end


#Random object that is used throughout for generating fake data that FFaker can't
r = Random.new

#Start script

if User.all.empty?
  STDOUT.puts "ERROR: You must sign into the app via CAS first to create a superuser account for your netID."
else
  #User generation
  entered_num = ask_for_records("User")

  if entered_num.integer? && entered_num > 0
    user = entered_num.times.map do
      User.create! do |u|
        u.first_name = Faker::Name.first_name
        u.last_name = Faker::Name.last_name
        u.nickname = Faker::Name.first_name
        u.phone = Faker::PhoneNumber.short_phone_number
        u.email = Faker::Internet.email
        u.login = (0...3).map{65.+(rand(25)).chr}.join.downcase + r.rand(2..99).to_s
        u.affiliation = "YC " + ["BK", "BR", "CC", "DC", "ES", "JE", "MC", "PC", "SM", "SY", "TC", "TD"].sample + " " + r.rand(2012..2015).to_s
        u.adminmode = false
        u.is_checkout_person = [true, false].sample
      end
    end
    user[0].is_checkout_person = true
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end


  #Category generation
  entered_num = ask_for_records("Category")

  if entered_num.integer? && entered_num > 0
    category = entered_num.times.map do
        Category.create! do |c|
        c.name = Faker::Product.brand + " " + r.rand(1..9001).to_s
        c.max_per_user = r.rand(1..40)
        c.max_checkout_length = r.rand(1..40)
        c.sort_order = r.rand(100)
        c.max_renewal_times = r.rand(0..40)
        c.max_renewal_length = r.rand(0..40)
        c.renewal_days_before_due = r.rand(0..9001)
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end


  #EquipmentModel generation
  entered_num = ask_for_records("EquipmentModel")
  STDOUT.puts "\nThis is going to take awhile...\n"
  if entered_num.integer? && entered_num > 0
    equipment_model = entered_num.times.map do
      EquipmentModel.create! do |em|
        em.name = Faker::Product.product + " " + r.rand(1..9001).to_s
        em.description = Faker::HipsterIpsum.paragraph(4)
        em.late_fee = r.rand(50.00..1000.00).round(2).to_d
        em.replacement_fee = r.rand(50.00..1000.00).round(2).to_d
        em.max_per_user = r.rand(1..40)
        em.active = true
        em.category_id = category.flatten[r.rand(0...category.length)].id
        em.max_renewal_times = r.rand(0..40)
        em.max_renewal_length = r.rand(0..40)
        em.renewal_days_before_due = r.rand(0..9001)
        em.photo = File.open(Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*')).sample)
        em.associated_equipment_models = EquipmentModel.all.sample(6)
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end


  #EquipmentObject generation
  entered_num = ask_for_records("EquipmentObject")

  if entered_num.integer? && entered_num > 0
    equipment_object = entered_num.times.map do
      EquipmentObject.create! do |eo|
        eo.name = "Number #{(0...3).map{65.+(rand(25)).chr}.join}" + r.rand(1..9001).to_s
        eo.serial = (0...8).map{65.+(rand(25)).chr}.join
        eo.active = true
        eo.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end

  #CheckinProcedure generation
  entered_num = ask_for_records("CheckinProcedure")

  if entered_num.integer? && entered_num > 0
    checkin_procedure = entered_num.times.map do
      CheckinProcedure.create! do |chi|
        chi.step = Faker::HipsterIpsum.sentence
        chi.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
  
  #CheckoutProcedure generation
  entered_num = ask_for_records("CheckoutProcedure")

  if entered_num.integer? && entered_num > 0
    checkin_procedure = entered_num.times.map do
      CheckinProcedure.create! do |cho|
        cho.step = Faker::HipsterIpsum.sentence
        cho.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
  
  #Reservation generation
  entered_num = ask_for_records("Reservation")
  
  if entered_num.integer? && entered_num > 0
    reservation = entered_num.times.map do
      random_time = time_rand Time.local(2012, 1, 1)
      random_due_date = time_rand(random_time, Time.now.next_week)

      Reservation.create! do |res|       
        res.reserver_id = user.flatten.sample.id
        res.checkout_handler_id = user.flatten.select{|usr| usr.is_checkout_person}.sample.id
        res.checkin_handler_id = user.flatten.select{|usr| usr.is_checkout_person}.sample.id
        res.start_date = random_time.to_datetime
        res.due_date = [random_due_date.to_datetime, (random_time + category.flatten.sample.max_checkout_length.days).to_datetime].sample
        res.checked_in = [nil, random_due_date.to_datetime, time_rand(random_due_date, random_due_date.next_month).to_datetime].sample
        res.checked_out = res.checked_in.nil? ? [nil, random_time.to_datetime].sample : random_time.to_datetime
        res.equipment_object_id = equipment_object.flatten.sample.id
        res.equipment_model_id = res.equipment_object.equipment_model_id
        res.notes = Faker::HipsterIpsum.paragraph(4)
        res.notes_unsent = [true, false].sample
      end
    end
    STDOUT.puts "\n#{entered_num} records successfully created!"
  else
    STDOUT.puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
  
end
