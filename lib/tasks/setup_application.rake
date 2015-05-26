require 'rake'

namespace :app do
  desc 'a rake task to set up the initial admin and configuration for '\
    'reservations site'
  task setup: :environment do
    # Welcome message and create admin user
    puts ''
    puts 'Welcome to reservations! Before using your application, we need '\
      'to create an'
    puts 'initial superuser account and set some application-wide '\
      'configurations.'
    puts 'This superuser account can be used later to create admins, '\
      'import users'
    puts 'and change any configurations that you set from this script. '\
      'With that'
    puts 'in mind, let\'s get started!'

    # ensure no _superusers_ have been created since guest users might have
    # been
    if User.where('role = ?', 'superuser').empty?
      User.destroy_all
      puts ''
      puts 'We need to start by creating a superuser account. Please enter the'
      puts 'following info:'

      until User.first # rubocop:disable Next
        puts ''
        puts 'First Name:'
        first_name = STDIN.gets.chomp
        puts 'Last Name:'
        last_name = STDIN.gets.chomp
        puts 'Phone #:'
        phone = STDIN.gets.chomp
        puts 'Email Address:'
        email = STDIN.gets.chomp
        if ENV['CAS_AUTH']
          puts 'Username (i.e. NetID, ensure this is correct):'
          cas_login = STDIN.gets.chomp
          username = cas_login
        else
          username = email
          puts 'Password:'
          password = STDIN.gets.chomp
          puts 'Confirm Password:'
          password_confirmation = STDIN.gets.chomp
        end
        puts 'Affiliation (i.e. Yale College):'
        affiliation = STDIN.gets.chomp

        ActiveRecord::Base.transaction do
          begin
            User.create! do |u|
              u.first_name = first_name
              u.last_name = last_name
              u.phone = phone
              u.email = email
              u.cas_login = cas_login if ENV['CAS_AUTH']
              u.username = username
              u.affiliation = affiliation
              u.role = 'superuser'
              u.view_mode = 'superuser'
              unless ENV['CAS_AUTH']
                u.password = password
                u.password_confirmation = password_confirmation
              end
            end
          rescue => e
            ActiveRecord::Rollback # rubocop:disable Lint/Void
            puts 'Oops! Your superuser account was not saved for the '\
              'reasons listed below'
            puts 'Please double check that you\'re entering valid '\
              "information for each item.\n"
            puts e
          end
        end # transaction

        if User.first
          puts 'Your user was saved successfully! Now we\'ll set the '\
            'application'
          puts 'configurations.'
        end
      end
    else
      puts ''
      puts 'There appears to already be a user in the database. If you wish '\
        'to run this'
      puts 'part of the setup script, please reset your database and run the'
      puts '$rake app:setup command again. You can use the command'
      puts '$rake db:migrate:reset to reset your database completely. '\
        'WARNING: This will'
      puts 'delete any information that you have already stored in the '\
        'database.'
    end

    # app config default variables
    DEFAULT_MSGS = File.join(Rails.root, 'db', 'default_messages')

    terms_of_service_text = File.read(File.join(DEFAULT_MSGS, 'tos_text'))

    upcoming_checkin_email_body = File.read(File.join(DEFAULT_MSGS,
                                                      'upcoming_checkin_email'))

    upcoming_checkout_email_body = File.read(File.join(DEFAULT_MSGS,
                                                       'upcoming_checkout_email'
                                                      ))

    overdue_checkin_email_body = File.read(File.join(DEFAULT_MSGS,
                                                     'overdue_email'))

    deleted_missed_reservation_email_body = File.read(File.join(
                                                        DEFAULT_MSGS,
                                                        'deleted_missed_email'))

    request_text =
      'The following equipment cannot be reserved because of admin '\
      'restrictions; however, you may file a request for this reservation. '\
      'Please fill out the form below and an admin will be able to approve '\
      'or deny your request. You will be notified by email when your '\
      'request has been reviewed.'

    # Create initial application configs.

    if AppConfig.all.empty?
      puts ''
      puts 'Please enter the following information to configure your '\
        'reservations'
      puts 'application:'

      until AppConfig.first # rubocop:disable Next
        puts ''
        puts 'Site title (this will show across the top of the browser '\
          'window when visiting'
        puts 'your site):'
        site_title = STDIN.gets.chomp
        puts 'Administrator Email (this email address will receive '\
          'administrator'
        puts 'notifications from the application):'
        admin_email = STDIN.gets.chomp
        puts 'Department Name (e.g. School of Art Digital Technology Office):'
        department_name = STDIN.gets.chomp
        puts "Home Link Text (this will be the name of your site's homepage):"
        home_link_text = STDIN.gets.chomp
        puts 'Home Link Location (e.g. http://clc.yale.edu):'
        home_link_location = STDIN.gets.chomp
        puts 'Contact Email (this email address will receive contact form '\
          'submissions). Leave blank to default to the admin e-mail.'
        if STDIN.gets.chomp.empty?
          contact_link_location = admin_email
        else
          contact_link_location = STDIN.gets.chomp
        end

        ActiveRecord::Base.transaction do
          begin
            AppConfig.create! do |ac|
              ac.terms_of_service = terms_of_service_text
              ac.upcoming_checkin_email_active = false
              ac.upcoming_checkout_email_active = false
              ac.reservation_confirmation_email_active = false
              ac.overdue_checkin_email_active = false
              ac.send_notifications_for_deleted_missed_reservations = false
              ac.upcoming_checkin_email_body = upcoming_checkin_email_body
              ac.upcoming_checkout_email_body = upcoming_checkout_email_body
              ac.deleted_missed_reservation_email_body =
                deleted_missed_reservation_email_body
              ac.overdue_checkin_email_body = overdue_checkin_email_body
              ac.site_title = site_title
              ac.admin_email = admin_email
              ac.department_name = department_name
              ac.home_link_text = home_link_text
              ac.home_link_location = home_link_location
              ac.request_text = request_text
              ac.default_per_cat_page = 20
              ac.viewed = false
              ac.blackout_exp_time = 30
              ac.contact_link_location = contact_link_location
            end
          rescue => e
            ActiveRecord::Rollback # rubocop:disable Lint/Void
            puts 'Your application settings were not saved for the reasons '\
              'listed below. Please'
            puts 'double check that you\'re entering valid input for each item.'
            puts e
          end
        end # transaction

        if AppConfig.first
          puts 'Congratulations! Your application has been setup '\
            'successfully. We highly'
          puts 'recommend that you now visit the site using the '\
            'administrator account that you'
          puts 'just created, and finish setting up the configurations that '\
            "we couldn't set"
          puts "from here. Thanks for using reservations, and don't "\
            'hesitate to submit any'
          puts 'issues or questions on our github page:'
          puts 'https://github.com/YaleSTC/reservations'
        end
      end
    else
      puts 'Application configurations appear to already be set. You can '\
        'edit application'
      puts 'configs by accessing the url ending in /app_configs from an '\
        'admin account. If'
      puts 'you do wish to reset everything, you can run the rake task'
      puts '$bundle exec rake db:migrate:reset, which will delete your '\
        'database completely'
      puts 'and build a new one. After running that command, please '\
        'remember to run this'
      puts 'script again.'
    end
  end
end
