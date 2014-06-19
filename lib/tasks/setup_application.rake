require 'rake'

namespace :app do
  desc 'a rake task to set up the initial admin and configuration for reservations site'
  task setup: :environment do

    # Welcome message and create admin user
    puts ''
    puts 'Welcome to reservations! Before using your application, we need to create an initial administrator account '
    puts 'and set some application-wide configurations. This administrator account can be used later to create other'
    puts "admins, import users, and change any configurations that you set from this script. With that in mind, let's get started!"

    if User.all.empty?
      puts ''
      puts 'We need to start by creating an admin account. Please enter the following info:'

      while !User.first
        puts ''
        puts 'First Name:'
        first_name = STDIN.gets.chomp
        puts 'Last Name:'
        last_name = STDIN.gets.chomp
        puts 'Phone #:'
        phone = STDIN.gets.chomp
        puts 'Email Address:'
        email = STDIN.gets.chomp
        puts 'Login (i.e. NetID, please double check that this is correct):'
        login = STDIN.gets.chomp
        puts 'Affiliation (i.e. Yale College):'
        affiliation = STDIN.gets.chomp

        ActiveRecord::Base.transaction do
          begin
            User.create! do |u|
              u.first_name = first_name
              u.last_name = last_name
              u.phone = phone
              u.email = email
              u.login = login
              u.affiliation = affiliation
              u.role = 'admin'
              u.view_mode = 'admin'
            end
          rescue Exception => e
            ActiveRecord::Rollback
            puts "Oops! Your admin account was not saved for the reasons listed below. Please double check that you're entering valid information for each item."
            puts e
          end
        end # transaction

        if User.first
          puts "Your user was saved successfully! Now we'll set the application configurations."
        end
      end
    else
      puts ''
      puts 'There appears to already be a user in the database. If you wish to run this part of the setup script, please reset your '
      puts 'database and run the $rake app:setup command again. You can use the command $rake db:migrate:reset to reset '
      puts 'your database completely. WARNING: This will delete any information that you have already stored in the database.'
    end

    # app config default variables
    terms_of_service_text =  %q{ No terms of service document has been uploaded yet. Please navigate to http://sitelocation/app_configs to add a ToS and edit other application configurations.}
    upcoming_checkin_email_body =
      "Dear @user@,\n\n"\
      "Hey there, you have equipment due! Please return the following items before 4pm on @return_date@.\n\n"\
      "@equipment_list@\n\n"\
      "If you fail to return your equipment on time the curse of @department_name@ will be placed upon you and your kin for 7 generations. Also, you will have to pay a late fee of @late_fee@ per day. If you have lost the item you may have to pay a replacement fee and/or sacrifice your first born child.\n"\
      "Log in to Reservations to see if any of your items are eligible for renewal. If you have further questions feel free to contact an employee of @department_name@.\n\n"\
      "Your reservation number is @reservation_id@.\n\n"\
      "Thank you,\n"\
      "@department_name@"

    deleted_missed_reservation_email_body =
      "Dear @user@,\n\n"\
      "You're in for it now! The darkness of @department_name@ is now upon you and your kin for the next 8 generations!\n\n"\
      "Please return the following equipment to us as soon as possible. Until then you will be charged a daily late fee of @late_fee@.\n\n"\
      "@equipment_list@\n\n"\
      "Failure to return equipment will result in the levying of replacement fees, revocation of borrowing privileges, and mandatory sacrificing of your first born child.\n\n"\
      "Your reservation number is @reservation_id@.\n\n"\
      "Thank you,\n"\
      "@department_name@"

    overdue_checkin_email_body =
      "Dear @user@,\n\n"\
      "Because you have missed a scheduled equipment checkout, your reservation (number @reservation_id@) has been cancelled. If you believe this is in error, please contact an administrator.\n\n"\
      "@equipment_list@\n\n"\
      "Thank you,\n"\
      "@department_name@ "

    # Create initial application configs.

    if AppConfig.all.empty?
      puts ''
      puts 'Please enter the following information to configure your reservations application:'

      while !AppConfig.first
        puts ''
        puts 'Site title (this will show across the top of the browser window when visiting your site):'
        site_title = STDIN.gets.chomp
        puts 'Administrator Email (this email address will receive administrator notifications from the application):'
        admin_email = STDIN.gets.chomp
        puts 'Department Name (e.g. School of Art Digital Technology Office):'
        department_name = STDIN.gets.chomp
        puts "Home Link Text (this will be the name of your site's homepage):"
        home_link_text = STDIN.gets.chomp
        puts 'Home Link Location (e.g. http://clc.yale.edu):'
        home_link_location = STDIN.gets.chomp

        ActiveRecord::Base.transaction do
          begin
            AppConfig.create! do |ac|
              ac.terms_of_service = terms_of_service_text
              ac.upcoming_checkin_email_active = false
              ac.reservation_confirmation_email_active = false
              ac.overdue_checkin_email_active = false
              ac.send_notifications_for_deleted_missed_reservations = false
              ac.upcoming_checkin_email_body = upcoming_checkin_email_body
              ac.deleted_missed_reservation_email_body = deleted_missed_reservation_email_body
              ac.overdue_checkin_email_body = overdue_checkin_email_body
              ac.site_title = site_title
              ac.admin_email = admin_email
              ac.department_name = department_name
              ac.home_link_text = home_link_text
              ac.home_link_location = home_link_location
              ac.default_per_cat_page = 20
              ac.viewed = false
            end
          rescue Exception => e
            ActiveRecord::Rollback
            puts "Your application settings were not saved for the reasons listed below. Please double check that you're entering valid input for each item."
            puts e
          end
        end # transaction

        if AppConfig.first
          puts 'Congratulations! Your application has been setup successfully. We highly recommend that you now visit the '
          puts 'site using the administrator account that you just created, and finish setting up the configurations that '
          puts "we couldn't set from here. Thanks for using reservations, and don't hesitate to submit any issues or questions "
          puts 'on our github page: https://github.com/YaleSTC/reservations'
        end
      end
    else
      puts 'Application configurations appear to already be set. You can edit application configs by accessing the url ending '
      puts 'in /app_configs from an admin account. If you do wish to reset everything, you can run the rake task $bundle exec '
      puts 'rake db:migrate:reset, which will delete your database completely and build a new one. After running that command, '
      puts 'please remember to run this script again.'
    end
  end
end

