# This script is used to populate the database with preload data.
# It does not clear the database - mainly because that would mean deleting your
# admin login. All the numbers are pretty arbitrary, and can be changed to suit
# your needs, and how many records you want.
#
# As it stands, you'll need to follow the format and create a new seed
# generation block for each model you want to seed in the database, every time
# you create a model that isn't already here.
#
# Order matters!! The script will fail if certain records (Catgeories,
# EquipmentModels) aren't generated first and in the order listed.
#
# Note that the "minimal" seed script (uses sane defaults instead of prompting
# for every value) is run by:
# ```bundle exec rake db:seed minimal=true```

require 'ffaker'
require 'ruby-progressbar'

#-------RESET PUBLIC DIR IF WE'VE RESET THE DATABASE
if EquipmentModel.all.empty?
  location_models = Rails.root.to_s + "/public/attachments/equipment_models"
  if File.directory?(location_models) # if the directory exists
    FileUtils.rm_r location_models # delete it and everything inside
  end
end


#-------METHODS

#Method for prompting the user for the number of records per model they want to seed into the database.
def ask_for_records(model)
  formatted_model = model.camelize

  puts "\nHow many #{formatted_model} records would you like to generate? (please enter a number)"
  STDIN.gets.chomp.to_i
end


def time_rand(from = 0.0, to = Time.now, length = 0, options = {})
  options[:passes_blackout_validations] = true

  range = to.to_f - from.to_f

  range = length.to_f if length > 0

  random_time = Time.at(from.to_f + rand * range)
  blackouts = Blackout.all.map { |blk| blk.start_date..blk.end_date }

  if options[:passes_blackout_validations] && !blackouts.blank?
    while includes?(blackouts, random_time)
      random_time = Time.at(from.to_f + rand * range)
    end
  end

  random_time
end

def includes?(array_of_ranges, elem)
  array_of_ranges.each do |rng|
    if rng.include?(elem)
      return true
    else
      return false
    end
  end
end

def terms_of_service_text
  %q{
## 1. Contract Formation
This product is meant for educational purposes only. Any resemblance to real persons, living or dead is purely coincidental. Void where prohibited. Some assembly required. List each check separately by bank number. Batteries not included.

## 2. Changes to the Agreement and Notices
Contents may settle during shipment. Use only as directed. No other warranty expressed or implied. Do not use while operating a motor vehicle or heavy equipment. Postage will be paid by addressee. Subject to CARB approval.
This is not an offer to sell securities. Apply only to affected area. May be too intense for some viewers. Do not stamp. Not rated by the Motion Picture Association of America. Call for nutritional information. Use other side for additional listings.

## 3. Grant of License
Printed on recycled paper. For recreational use only. Do not disturb. All models over 18 years of age. Prize not redeemable for cash value. If condition persists, consult your physician. No user-serviceable parts inside. Freshest if eaten before date on carton.
To be used as a supplementary restraint system only. Always fasten your safety belt. Subject to change without notice. Times approximate. Simulated picture. Do not staple or paper clip. Price slightly higher east of Alaska. No postage necessary if mailed in the United States.
Do not X-ray. Breaking seal constitutes acceptance of agreement. For off-road use only. As seen on TV. One size fits all. Many suitcases look alike. Contains a substantial amount of non-tobacco ingredients. Colors may, in time, fade.
We have sent the forms which seem right for you. Magnetic media, non-returnable if seal is broken. Formatted to fit your screen. Slippery when wet. For office use only. Not affiliated with the American Red Cross. Drop in any mailbox. Edited for television.

## 4. Third Party Applications and Third Party Applications Content
Keep cool, process promptly. Post office will not deliver without postage. List was current at time of printing. Return to sender, no forwarding order on file, unable to forward. Prolong exposure to vapors has caused cancer in laboratory animals.
Not responsible for direct, indirect, incidental or consequential damages resulting from any defect, error or failure to perform. Keep away from children. At participating locations only. Not the Beatles. Penalty for private use. See label for sequence.
Substantial penalty for early withdrawal. Do not write below this line. Falling rock. Lost ticket pays maximum rate. Phenylketonurics: contains phenylalnine. Your canceled check is your receipt. Add toner. Place stamp here.

## 5. Restrictions of Use
Use only as directed; intentional misuse by deliberately concentrating and inhaling contents can be harmful or fatal. Avoid contact with skin. Road construction ahead. Open other end. Dealer participation may affect final price.
May not be present in all tap water. Sanitized for your protection. Be sure each item is properly endorsed. Sign here without admitting guilt. Slightly higher west of the Mississippi. Park at your own risk. Employees and their families and friends are not eligible. Beware of dog.
Contestants have been briefed on some questions before the show. Limited time offer, call now to ensure prompt delivery. You must be present to win. No passes accepted for this engagement. No purchase necessary. Processed at location stamped in code at top of
carton.

## 6. NO WARRANTY
Shading within a garment may occur. Keep away from fire or flames. See Uniform Code of Military Justice. Replace with same type. Approved for veterans. Booths for two or more. Indicates a low-fat item. Check here if tax deductible. Some equipment shown is optional.
Price does not include taxes. No Canadian coins. Tax, tag, and title not included in advertised price. Not recommended for children. Prerecorded for this time zone. Reproduction by mechanical or electronic means, including photocopying, is strictly prohibited.
No solicitors. No alcohol, dogs or horses. No anchovies unless otherwise specified. Avoid spraying into eyes. An 18% gratuity will be added for parties of 8 or more. Do not write under this line.
  }
end


# Random object that is used throughout for generating fake data that FFaker can't
r = Random.new

# Progress bar format string
progress_str = "%t: [%B] %P%% | %c / %C | %E"

# initialize arrays for objects created this session
user = []
category = []
equipment_model = []
equipment_object = []
requirement = []
checkin_procedure = []
checkout_procedure = []
reservation = []
blackout = []


# START SCRIPT
# ============

if ENV["minimal"]
  puts "Minimal mode activated. Please wait..."
end

if User.all.empty?
  unless ENV["minimal"]
    puts 'We need to create an account for you first. Please enter the following info:'
    puts 'First Name:'
    first_name = STDIN.gets.chomp
    puts 'Last Name:'
    last_name = STDIN.gets.chomp
    puts 'Phone #:'
    phone = STDIN.gets.chomp
    puts 'Email Address:'
    email = STDIN.gets.chomp
    puts 'Affiliation:'
    affiliation = STDIN.gets.chomp
    if ENV['CAS_AUTH']
      puts 'Username (i.e. NetID):'
    else
      puts 'Password'
    end
  else
    first_name = "Donny"
    last_name = "Darko"
    phone = "6666666666"
    email = "email@email.com"
    affiliation = "Your Mother"
    puts "Please enter your netID" if ENV['CAS_AUTH']
  end
  if ENV['CAS_AUTH']
    username = STDIN.gets.chomp
  else
    username = email
    password = 'passw0rd'
    password_confirmation = 'passw0rd'
  end

  User.create! do |u|
    u.first_name = first_name
    u.last_name = last_name
    u.phone = phone
    u.email = email
    u.username = username
    u.affiliation = affiliation
    u.role = 'superuser'
    u.view_mode = 'superuser'
    unless ENV['CAS_AUTH']
      u.password = password
      u.password_confirmation = password_confirmation
    end
  end
end

# User generation
# ============================================================================

if ENV["minimal"]
  entered_num = 25
else
  entered_num = ask_for_records('User')
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)

    user = entered_num.times.map do
      progress.increment
      User.create do |u|
        u.first_name = Faker::Name.first_name
        u.last_name = Faker::Name.last_name
        u.nickname = Faker::Name.first_name
        u.phone = Faker::PhoneNumber.short_phone_number
        u.email = Faker::Internet.email
        u.username = (0...3).map{65.+(rand(25)).chr}.join.downcase + r.rand(2..99).to_s
        u.affiliation = 'YC ' + %w{BK BR CC DC ES JE MC PC SM SY TC TD}.sample + ' ' + r.rand(2012..2015).to_s
        u.role = ['normal', 'checkout'].sample
      end

    end
    user[0].role ='checkout' # hack to ensure at least one checkout person is created every time
    puts "\n#{entered_num} user records successfully created!"
  else
    puts "\nPlease enter a whole number"
    entered_num = STDIN.gets.chomp.to_i
  end
else
  user << User.first
  puts "\n***Any reservation records you create will
   be assigned to the first user, #{user.first.name}.
   If this is not your intent, please exit now (Ctrl+C)
   or remember to enter zero for reservations later on.***\n\n"
end

# Terms of Service generation
# ============================================================================

if AppConfig.all.empty?

# TODO: Validate user input
  if ENV["minimal"]
    admin_email = "admin@admin.com"
    department_name = "Department"
    contact_link_location = "wtf"
    home_link_text = "home_link"
    home_link_location = "Canada"
  else
    puts "We need to setup application settings:"
    puts "Admin Email Address:"
    admin_email = STDIN.gets.chomp
    puts "Department Name:"
    department_name = STDIN.gets.chomp
    puts "Contact Link location:"
    contact_link_location = STDIN.gets.chomp
    puts "Home Link Text:"
    home_link_text = STDIN.gets.chomp
    puts "Home Link location:"
    home_link_location = STDIN.gets.chomp
  end
  AppConfig.create! do |ac|
    ac.terms_of_service = terms_of_service_text
    ac.upcoming_checkin_email_active = false
    ac.reservation_confirmation_email_active = false
    ac.overdue_checkin_email_active = false
    ac.site_title = "Reservations"
    ac.admin_email = admin_email
    ac.department_name = department_name
    ac.contact_link_location = contact_link_location
    ac.home_link_text = home_link_text
    ac.home_link_location = home_link_location
    ac.default_per_cat_page = 10
  end
else
  ac = AppConfig.first
  ac.terms_of_service = terms_of_service_text
  ac.save!
end

# Category generation
# ============================================================================

if ENV["minimal"]
  entered_num = 10
else
  entered_num = ask_for_records('Category')
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    category_names = Category.all.to_a.map! { |c| c.name }
    progress = ProgressBar.create(format: progress_str, total: entered_num)

    category = entered_num.times.map do
      progress.increment
      Category.create! do |c|
        category_name = Faker::Product.brand

        # Verify uniqueness of category name
        while category_names.include?(category_name)
          category_name = Faker::Product.brand
        end

        c.name = category_name
        category_names << c.name

        c.max_per_user = r.rand(1..40)
        c.max_checkout_length = r.rand(1..40)
        c.sort_order = r.rand(100)
        c.max_renewal_times = r.rand(0..40)
        c.max_renewal_length = r.rand(0..40)
        c.renewal_days_before_due = r.rand(0..9001)
      end
    end
    puts "\n#{entered_num} category records successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
else
  puts "\n***To seed equipment models, objects, blackout dates,
   requirements, reservations, etc, you must create
   at least one category. Exiting seed script........***\n\n"
  exit
end

# EquipmentModel generation
# ============================================================================

if ENV["minimal"]
  entered_num = 25
else
  entered_num = ask_for_records("EquipmentModel")
end


unless entered_num == 0
  puts "\nThis is going to take awhile...\n"
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    equipment_model = entered_num.times.map do
      progress.increment
      EquipmentModel.create! do |em|
        em.name = Faker::Product.product + " " + r.rand(1..9001).to_s
        em.description = Faker::HipsterIpsum.paragraph(16)
        em.late_fee = r.rand(50.00..1000.00).round(2).to_d
        em.replacement_fee = r.rand(50.00..1000.00).round(2).to_d
        em.category_id = category.flatten[r.rand(0...category.length)].id
        em.max_per_user = r.rand(1..em.category.max_per_user)
        em.active = true
        em.max_renewal_times = r.rand(0..40)
        em.max_renewal_length = r.rand(0..40)
        em.renewal_days_before_due = r.rand(0..9001)
        em.photo = File.open(Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*')).sample)
        em.associated_equipment_models = EquipmentModel.all.sample(6)
      end
    end
    puts "\n#{entered_num} equipment model records successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
else
  puts "\n***To seed equipment objects, blackout dates,
   requirements, reservations, etc, you must create
   at least one equipment model. Exiting seed script...***\n\n"
  exit
end

# Requirement generation
# ============================================================================

if ENV["minimal"]
  entered_num = 0
else
  entered_num = ask_for_records("Requirement")
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    requirement = entered_num.times.map do
      progress.increment
      Requirement.create! do |req|
        req.equipment_models = equipment_model.sample(r.rand(1..3))
        req.contact_name = Faker::Name.name
        req.contact_info = Faker::PhoneNumber.short_phone_number
        req.notes = Faker::HipsterIpsum.paragraph(4)
        req.description = Faker::HipsterIpsum.sentence
      end
    end
    puts "\n#{entered_num} requirement records successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
end

# CheckinProcedure generation
# ============================================================================

if ENV["minimal"]
  entered_num = 3
else
  entered_num = ask_for_records("CheckinProcedure")
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    checkin_procedure = entered_num.times.map do
      progress.increment
      CheckinProcedure.create! do |chi|
        chi.step = Faker::HipsterIpsum.sentence
        chi.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    puts "\n#{entered_num} check-in procedures successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
end

# CheckoutProcedure generation
# ============================================================================

if ENV["minimal"]
  entered_num = 3
else
  entered_num = ask_for_records("CheckoutProcedure")
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    checkout_procedure = entered_num.times.map do
      progress.increment
      CheckoutProcedure.create! do |cho|
        cho.step = Faker::HipsterIpsum.sentence
        cho.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    puts "\n#{entered_num} checkout procedures successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
end

# Blackout Date generation
# ============================================================================

if ENV["minimal"]
  entered_num = 0
else
  entered_num = ask_for_records("Blackout Dates")
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)

    blackout = entered_num.times.map do
      random_time_in_past = time_rand(Time.now + 1.year)
      random_end_date = time_rand(random_time_in_past, random_time_in_past.next_week)
      progress.increment

      Blackout.create! do |blk|
        blk.start_date = random_time_in_past
        blk.end_date = random_end_date
        blk.notice = Faker::HipsterIpsum.paragraph(2)
        blk.created_by = User.first.id
        blk.blackout_type = ['soft', 'hard'].sample
        blk.equipment_model_id = 0
      end
    end
    puts "\n#{entered_num} blackout date records successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
end

# EquipmentObject generation
# ============================================================================

if ENV["minimal"]
  entered_num= 50
else
  entered_num = ask_for_records("EquipmentObject")
end

unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    equipment_object = entered_num.times.map do
      progress.increment
      EquipmentObject.create! do |eo|
        eo.name = "Number #{(0...3).map{65.+(rand(25)).chr}.join}" + r.rand(1..9001).to_s
        eo.serial = (0...8).map{65.+(rand(25)).chr}.join
        eo.active = true
        eo.equipment_model_id = equipment_model.flatten.sample.id
      end
    end
    puts "\n#{entered_num} equipment object records successfully created!"
  else
    puts "\nPlease enter a whole number greater than 0."
    entered_num = STDIN.gets.chomp.to_i
  end
else
  puts "\n***To seed reservation records, you must create at least
   one equipment object. If this was your intent, you're
   good to go. Exiting seed script......................***\n\n"
  exit
end

# Reservation generation
# ============================================================================

if ENV["minimal"]
  entered_num = 10
else
  entered_num = ask_for_records("Reservation")
end


unless entered_num == 0
  if entered_num.integer? && entered_num > 0
    progress = ProgressBar.create(format: progress_str, total: entered_num)
    reservation = entered_num.times.map do
      random_time_in_future = time_rand(Time.now, Time.now + 2.months)
      # random_due_date = time_rand(random_time_in_past, Time.now.next_week, category.flatten.sample)
      progress.increment
      Reservation.create! do |res|
        res.reserver_id = user.flatten.sample.id
        res.checkout_handler_id = user.flatten.select{|usr| usr.role == "admin" || usr.role == "checkout"}.sample.id
        res.checkin_handler_id = user.flatten.select{|usr| usr.role == "admin" || usr.role == "checkout"}.sample.id
        res.equipment_object_id = equipment_object.flatten.sample.id
        res.equipment_model_id = res.equipment_object.equipment_model_id
        res.start_date = random_time_in_future.to_datetime
        res.due_date = time_rand(res.start_date.to_time, res.start_date.next_week, res.equipment_model.category.max_checkout_length).to_datetime
        res.checked_in = [nil, time_rand(random_time_in_future, random_time_in_future.next_week,
                          res.equipment_model.category.max_checkout_length).to_datetime].sample
        res.checked_out = res.checked_in.nil? ? [nil, random_time_in_future.to_datetime].sample : random_time_in_future.to_datetime
        res.notes = Faker::HipsterIpsum.paragraph(8)
        res.notes_unsent = [true, false].sample
      end
    end

    # TODO: only generate dates that are not blackout dates
    to_fling_into_the_past = reservation.sample(rand((entered_num / 4)..entered_num))
    to_fling_into_the_past.each do |res|
      random_time_in_past = time_rand(Time.now - 2.months)
      res.update_attribute(:start_date, random_time_in_past.to_datetime)
      res.update_attribute(:due_date, time_rand(res.start_date.to_time, Time.now.next_week, res.equipment_model.category.max_checkout_length).to_datetime)
      res.update_attribute(:checked_in, [nil, time_rand(random_time_in_past, Time.now.next_week, res.equipment_model.category.max_checkout_length).to_datetime].sample)
      res.update_attribute(:checked_out, res.checked_in.nil? ? [nil, random_time_in_past.to_datetime].sample : random_time_in_past.to_datetime)
    end

    puts "\n#{entered_num} reservation records successfully created!"
    else
      puts "\nPlease enter a whole number greater than 0."
      entered_num = STDIN.gets.chomp.to_i
    end
end

puts "\n***Successfully seeded all records!***\n\n"
puts "You can log in using the e-mail 'email@email.com' and password 'passw0rd'\n\n" if (!ENV['CAS_AUTH'] && ENV['minimal'])
