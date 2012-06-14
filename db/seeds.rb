# This script is used by the gem seed-fu to populate the database with preload data. 
# It does not clear the database - mainly because that would mean deleting your admin login.
# All the numbers are pretty arbitrary, and can be changed to suit your needs, and how many records you want.
# As it stands, you'll need to follow the format and create a new seed generation block for each
# model you want to seed in the database, every time you create a model that isn't already here.
# Right now, it only generates Users, Categories, EquipmentModels, and EquipmentObjects.

require 'ffaker'

#Method for prompting the user for the number of records per model they want to seed into the database.
def ask_for_records( model )
  STDOUT.puts "How many #{model} records would you like to generate? (please enter a number)"
  STDIN.gets.chomp.to_i
end


#Random object that is used throughout for generating fake data that FFaker can't
r = Random.new

if User.all.empty?
  STDOUT.puts "ERROR: You must sign into the app via CAS first to create a superuser account for your netID."
else
  #User generation
  entered_num = ask_for_records("User")

  if entered_num.integer? && entered_num >= 0
    entered_num.times do
      User.create! do |u|
        u.first_name = Faker::Name.first_name
        u.last_name = Faker::Name.last_name
        u.nickname = Faker::Name.first_name
        u.phone = Faker::PhoneNumber.short_phone_number
        u.email = Faker::Internet.email
        u.login = (0...3).map{65.+(rand(25)).chr}.join.downcase + r.rand(2..99).to_s
        u.affiliation = "YC " + ["BK", "BR", "CC", "DC", "ES", "JE", "MC", "PC", "SM", "SY", "TC", "TD"].sample + " " + r.rand(2012..2015).to_s
      end
    end
    STDOUT.puts "#{entered_num} records successfully created!"
  else
    STDOUT.puts "Please enter a whole number."
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
      end
    end
    STDOUT.puts "#{entered_num} records successfully created!"
  else
    STDOUT.puts "Please enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end


  #EquipmentModel generation
  entered_num = ask_for_records("EquipmentModel")

  if entered_num.integer? && entered_num > 0
    equipment_model = entered_num.times.map do
      EquipmentModel.create! do |em|
        em.name = Faker::Product.product + " " + r.rand(1..9001).to_s
        em.description = Faker::Lorem.paragraph(4)
        em.late_fee = r.rand(50.00..1000.00).round(2).to_d
        em.replacement_fee = r.rand(50.00..1000.00).round(2).to_d
        em.max_per_user = r.rand(1..40)
        em.active = true
        #em.checkout_procedures = Faker::Lorem.sentences(4)
        #em.checkin_procedures = Faker::Lorem.sentences(4)
        em.category_id = category.flatten[r.rand(0...category.length)].id
      end
    end
    STDOUT.puts "#{entered_num} records successfully created!"
  else
    STDOUT.puts "Please enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end


  #EquipmentObject generation
  entered_num = ask_for_records("EquipmentObject")

  if entered_num.integer? && entered_num >= 0
    entered_num.times do
      EquipmentObject.create! do |eo|
        eo.name = "Number #{(0...3).map{65.+(rand(25)).chr}.join}" + r.rand(1..9001).to_s
        eo.serial = (0...8).map{65.+(rand(25)).chr}.join
        eo.active = true
        eo.equipment_model_id = equipment_model.flatten[r.rand(0...equipment_model.length)].id
      end
    end
    STDOUT.puts "#{entered_num} records successfully created!"
  else
    STDOUT.puts "Please enter a whole number."
    entered_num = STDIN.gets.chomp.to_i
  end
end
