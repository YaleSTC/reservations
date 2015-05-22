# This script is used to populate the database with preload data.
# It does not clear the database - mainly because that would mean deleting your
# admin login. All the numbers are pretty arbitrary, and can be changed to suit
# your needs, and how many records you want.
#
# As it stands, you'll need to follow the format and create a new seed
# generation block for each model you want to seed in the database, every time
# you create a model that isn't already here.
#
# There are a variety of options passable to the script through the use of
# environment variables, eg
# ```bundle exec rake db:seed semi=true no_pics=true```
#
# semi
#   autogenerates the first user and appconfig but prompts for all other fields
# minimal (or auto)
#   autogenerates all fields with sane defaults
# no_pics
#   does not assign pictures to equipment models, saving around 1 second
#   per equipment model generated
# fast
#   combines minimal and no_pics

require 'ffaker'
require 'ruby-progressbar'

# rubocop:disable Rails/Output

#-------RESET PUBLIC DIR IF WE'VE RESET THE DATABASE
if EquipmentModel.all.empty?
  location_models = Rails.root.to_s + '/public/attachments/equipment_models'
  if File.directory?(location_models) # if the directory exists
    FileUtils.rm_r location_models # delete it and everything inside
  end
end

#-------GLOBAL VARIABLES

MINIMAL = ENV['minimal'].present? || ENV['fast'].present?
SEMI = ENV['semi'].present?
NO_PICS = ENV['no_pics'].present? || ENV['fast'].present?

DEFAULT_MSGS = File.join(Rails.root, 'db', 'default_messages')
TOS_TEXT = File.read(File.join(DEFAULT_MSGS, 'tos_text'))
UPCOMING_CHECKIN_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                 'upcoming_checkin_email'))
UPCOMING_CHECKOUT_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                  'upcoming_checkout_email'))
OVERDUE_RES_EMAIL_BODY = File.read(File.join(DEFAULT_MSGS, 'overdue_email'))
DELETED_MISSED_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                               'deleted_missed_email'))

# max number of attempts to build valid record before quitting
MAX_TRIES = 50

# ratio of old reservations to new
PAST_CHANCE = 0.7

# odds a checked out reservation is overdue
OVERDUE_CHANCE = 0.3

# odds a scheduled reservation has not been picked up
MISSED_CHANCE = 0.2

# time in the future reservations could be scheduled
FUTURE_RANGE = 3.months

# time in the past reservations could be scheduled
PAST_RANGE = 1.year

IMAGES = Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*'))

# Progress bar format string
PROGRESS_STR = '%t: [%B] %P%% | %c / %C | %E'

#-------METHODS

# Method for prompting the user for the number of records per model
# they want to seed into the database.
def ask_for_records(model)
  formatted_model = model.camelize

  puts "\nHow many #{formatted_model} records would you like to generate?" \
    '(please enter a number)'
  n = STDIN.gets.chomp
  # set n to 0 if blank, otherwise try to convert to an int.
  # if that fails re-prompt
  n = 0 if n == ''
  n = Integer(n) rescue nil # rubocop:disable RescueModifier
  if n.nil? || n < 0
    puts "Please enter a whole number\n"
    return ask_for_records(model)
  end
  n
end

def prompt_field(obj, field)
  puts field.to_s.split('_').collect(&:capitalize).join(' ') + ':'
  obj[field] = STDIN.gets.chomp
  begin
    obj.save!
  rescue ActiveRecord::RecordInvalid => e
    puts e.to_s
    prompt_field(obj, field)
  end
end

def prompt_password(user)
  puts 'Temp Password:'
  user.password = STDIN.gets.chomp
  user.password_confirmation = user.password
  begin
    user.save!
  rescue ActiveRecord::RecordInvalid => e
    puts e.to_s
    prompt_password(user)
  end
end

def time_rand(from = 0.0, to = Time.zone.now, length = 0, options = {})
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
    return rng.include?(elem)
  end
end

def generate_user # rubocop:disable AbcSize
  User.create do |u|
    u.first_name = Faker::Name.first_name
    u.last_name = Faker::Name.last_name
    u.nickname = Faker::Name.first_name
    u.phone = Faker::PhoneNumber.short_phone_number
    u.email = Faker::Internet.email
    u.cas_login = Faker::Internet.user_name if ENV['CAS_AUTH']
    u.affiliation = 'YC ' + %w(BK BR CC DC ES JE MC PC SM SY TC TD).sample +
      ' ' + rand(2012..2015).to_s
    u.role = %w(normal checkout).sample
    u.username = ENV['CAS_AUTH'] ? u.cas_login : u.email
  end
end

def generate_category
  Category.create! do |c|
    category_name = Faker::Product.brand
    category_names = Category.all.to_a.map!(&:name)

    # Verify uniqueness of category name
    while category_names.include?(category_name)
      category_name = Faker::Product.brand
    end

    c.name = category_name

    c.max_per_user = rand(1..40)
    c.max_checkout_length = rand(1..40)
    c.sort_order = rand(100)
    c.max_renewal_times = rand(0..40)
    c.max_renewal_length = rand(0..40)
    c.renewal_days_before_due = rand(0..9001)
  end
end

# rubocop:disable AbcSize
def generate_em
  EquipmentModel.create! do |em|
    em.name = Faker::Product.product + ' ' + rand(1..9001).to_s
    em.description = Faker::HipsterIpsum.paragraph(16)
    em.late_fee = rand(50.00..1000.00).round(2).to_d
    em.replacement_fee = rand(50.00..1000.00).round(2).to_d
    em.category = Category.all.sample
    em.max_per_user = rand(1..em.category.max_per_user)
    em.active = true
    em.max_renewal_times = rand(0..40)
    em.max_renewal_length = rand(0..40)
    em.renewal_days_before_due = rand(0..9001)
    em.photo = File.open(IMAGES.sample) unless NO_PICS
    em.associated_equipment_models = EquipmentModel.all.sample(6)
  end
end
# rubocop:enable AbcSize

def generate_ei
  EquipmentItem.create! do |ei|
    ei.name = "Number #{(0...3).map { 65.+(rand(25)).chr }.join}" +
      rand(1..9001).to_s
    ei.serial = (0...8).map { 65.+(rand(25)).chr }.join
    ei.active = true
    ei.equipment_model_id = EquipmentModel.all.sample.id
    ei.notes = ''
  end
end

def generate_req
  Requirement.create! do |req|
    req.equipment_models = EquipmentModel.all.sample(rand(1..3))
    req.contact_name = Faker::Name.name
    req.contact_info = Faker::PhoneNumber.short_phone_number
    req.notes = Faker::HipsterIpsum.paragraph(4)
    req.description = Faker::HipsterIpsum.sentence
  end
end

def generate_checkin
  CheckinProcedure.create! do |chi|
    chi.step = Faker::HipsterIpsum.sentence
    chi.equipment_model_id = EquipmentModel.all.sample.id
  end
end

def generate_checkout
  CheckoutProcedure.create! do |chi|
    chi.step = Faker::HipsterIpsum.sentence
    chi.equipment_model_id = EquipmentModel.all.sample.id
  end
end

def generate_blackout
  Blackout.create! do |blk|
    blk.start_date = time_rand(Time.now + 1.year)
    blk.end_date = time_rand(blk.start_date.to_time,
                             blk.start_date.next_week.to_time)
    blk.notice = Faker::HipsterIpsum.paragraph(2)
    blk.created_by = User.first.id
    blk.blackout_type = %w(soft hard).sample
  end
end

def mark_checked_in(res, checkout_length)
  return unless res.checked_out
  if rand < OVERDUE_CHANCE
    res.overdue = true
    res.status = 'checked_out'
    res.checked_in = nil
  else
    res.status = 'returned'
    res.checked_in = time_rand(res.checked_out, res.checked_out.next_week,
                               checkout_length).to_datetime
    res.checkin_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                        'checkout', 'admin', 'superuser'
                                     ).all.sample.id
  end
end

def mark_checked_out(res)
  if rand < MISSED_CHANCE
    res.checked_out = nil
    res.status = 'missed'
  else
    res.status = 'checked_out'
    res.checked_out = res.start_date
    res.equipment_item = res.equipment_model.equipment_items.all.sample
    res.checkout_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                         'checkout', 'admin', 'superuser'
                                        ).all.sample.id
  end
end

def throw_into_past(res)
  factor = rand(1.day..PAST_RANGE)
  res.start_date = res.start_date - factor
  res.due_date = res.due_date - factor
  mark_checked_out res
  mark_checked_in(res, res.equipment_model.category.max_checkout_length)
  res.save(validate: false)
end

# rubocop:disable AbcSize, MethodLength
def generate_reservation
  count = 0
  while count < MAX_TRIES
    res = Reservation.new
    res.status = 'reserved'
    res.reserver_id = User.all.sample.id
    res.equipment_model = EquipmentModel.all.sample
    res.start_date = time_rand(Time.zone.now,
                               Time.zone.now + FUTURE_RANGE).to_date

    checkout_length = res.equipment_model.category.max_checkout_length
    res.due_date = time_rand(res.start_date.to_datetime,
                             res.start_date.to_datetime.next_week,
                             checkout_length.days).to_date
    res.notes = Faker::HipsterIpsum.paragraph(8)
    res.notes_unsent = [true, false].sample
    if rand < PAST_CHANCE
      throw_into_past res
      return
    end
    try_again = false
    begin
      res.save!
    rescue ActiveRecord::RecordInvalid
      try_again = true
    end
    return unless try_again
    count += 1
  end
end
# rubocop:enable AbcSize

def generate_objs(method, obj, n)
  return if n == 0
  progress = ProgressBar.create(format: PROGRESS_STR, total: n)
  n.times.map do
    progress.increment
    send(method)
  end
  puts "\n#{n} #{obj.camelize} records successfully created!"
end

# START SCRIPT
# ============
#

puts 'Minimal mode activated. Please wait...' if MINIMAL

t1 = Time.now
display_login_msg = false
# check to see if a superuser exists
if User.where('role = ?', 'superuser').empty?
  display_login_msg = true
  User.destroy_all
  u = User.new
  u.first_name = 'Donny'
  u.last_name = 'Darko'
  u.phone = '6666666666'
  u.email = 'email@email.com'
  u.affiliation = 'Your Mother'
  u.role = 'superuser'
  u.view_mode = 'superuser'
  u.username = 'dummy'
  u.save

  if MINIMAL || SEMI
    if ENV['CAS_AUTH']
      prompt_field(u, :cas_login)
      u.username = u.cas_login
    else
      u.username = u.email
      u.password = 'passw0rd'
      u.password_confirmation = u.password
      u.save
    end
  else
    puts 'We need to create an account for you first.' \
      'Please enter the following info:'
    prompt_field(u, :first_name)
    prompt_field(u, :last_name)
    prompt_field(u, :phone)
    prompt_field(u, :email)
    prompt_field(u, :affiliation)
    if ENV['CAS_AUTH']
      prompt_field(u, :cas_login)
      u.username = u.cas_login
    else
      u.username = u.email
      u.save
      prompt_password(u)
    end
  end

end

# AppConfig generation
# ============================================================================

if AppConfig.count == 0

  ac = AppConfig.new
  ac.terms_of_service = TOS_TEXT
  ac.reservation_confirmation_email_active = false
  ac.overdue_checkin_email_active = false
  ac.site_title = 'Reservations'
  ac.upcoming_checkin_email_active = false
  ac.admin_email = 'admin@admin.com'
  ac.department_name = 'Department'
  ac.contact_link_location = 'link'
  ac.home_link_text = 'home_link'
  ac.home_link_location = 'Canada'
  ac.deleted_missed_reservation_email_body = DELETED_MISSED_RES_EMAIL
  ac.default_per_cat_page = 10
  ac.request_text = ''
  ac.upcoming_checkin_email_body = UPCOMING_CHECKIN_RES_EMAIL
  ac.upcoming_checkout_email_body = UPCOMING_CHECKOUT_RES_EMAIL
  ac.overdue_checkin_email_body = OVERDUE_RES_EMAIL_BODY
  ac.save

  unless MINIMAL || SEMI
    puts 'We need to setup application settings:'
    prompt_field(ac, :admin_email)
    prompt_field(ac, :department_name)
    printf 'The contact form email - '
    prompt_field(ac, :contact_link_location)
    prompt_field(ac, :home_link_text)
    prompt_field(ac, :home_link_location)
    prompt_field(ac, :site_title)
  end
end

# User generation

n = MINIMAL ? 25 : ask_for_records('User')
generate_objs(:generate_user, 'user', n)

# Category generation
# ============================================================================

n = MINIMAL ? 10 : ask_for_records('Category')

generate_objs(:generate_category, 'category', n)

# EquipmentModel generation
# ============================================================================

unless Category.count == 0
  n = MINIMAL ? 25 : ask_for_records('EquipmentModel')
  puts "\nThis is going to take awhile...\n" unless NO_PICS
  generate_objs(:generate_em, 'equipment_model', n)
end

# Eqobj, Procedures, and Requirement generation
# ============================================================================

unless EquipmentModel.count == 0

  n = MINIMAL ? 50 : ask_for_records('EquipmentItem')
  generate_objs(:generate_ei, 'equipment_item', n)

  n = MINIMAL ? 0 : ask_for_records('Requirement')
  generate_objs(:generate_req, 'requirement', n)

  n = MINIMAL ? 3 : ask_for_records('CheckinProcedure')
  generate_objs(:generate_checkin, 'checkin_procedure', n)

  n = MINIMAL ? 3 : ask_for_records('CheckoutProcedure')
  generate_objs(:generate_checkout, 'checkout_procedure', n)

end

# Blackout Date generation
# ============================================================================

n = MINIMAL ? 0 : ask_for_records('Blackout')
generate_objs(:generate_blackout, 'blackout', n)

# Reservation generation
# ============================================================================

unless EquipmentItem.count == 0
  n = MINIMAL ? 10 : ask_for_records('Reservation')
  generate_objs(:generate_reservation, 'reservation', n)
end

puts "\n***Successfully seeded all records! (#{Time.now - t1}s)***\n\n"
if !ENV['CAS_AUTH'] && MINIMAL && display_login_msg
  puts "You can log in using e-mail 'email@email.com' and password 'passw0rd'\n"
end
