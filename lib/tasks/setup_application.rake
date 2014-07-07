require 'rake'

namespace :app do
  desc 'a rake task to set up the initial admin and configuration for reservations site'
  task setup: :environment do

    # Welcome message and create admin user
    puts ''
    puts 'Welcome to reservations! Before using your application, we need to create an'
    puts 'initial administrator account and set some application-wide configurations.'
    puts 'This administrator account can be used later to create other admins, import'
    puts 'users, and change any configurations that you set from this script. With'
    puts "that in mind, let's get started!"

    if User.all.empty?
      puts ''
      puts 'We need to start by creating an admin account. Please enter the'
      puts 'following info:'

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
            puts "Oops! Your admin account was not saved for the reasons listed below. Please"
            puts "double check that you're entering valid information for each item.\n"
            puts e
          end
        end # transaction

        if User.first
          puts "Your user was saved successfully! Now we'll set the application"
          puts "configurations."
        end
      end
    else
      puts ''
      puts 'There appears to already be a user in the database. If you wish to run this'
      puts 'part of the setup script, please reset your database and run the'
      puts '$rake app:setup command again. You can use the command'
      puts '$rake db:migrate:reset to reset your database completely. WARNING: This will'
      puts 'delete any information that you have already stored in the database.'
    end

    # app config default variables
    terms_of_service_text =  %q{ No terms of service document has been uploaded yet. Please navigate to http://sitelocation/app_configs to add a ToS and edit other application configurations.}
    upcoming_checkin_email_body =
      "Dear @user@,\n\n"\
      "Hey there, you have equipment due! Please return the following items before 4pm on @return_date@.\n\n"\
      "@equipment_list@\n\n"\
      "If you fail to return your equipment on time you will be subject to a late fee of @late_fee@ per day. If you have lost the item you may additioally have to pay a replacement fee of @replacement_fee@.\n"\
      "Log in to Reservations to see if any of your items are eligible for renewal. If you have further questions feel free to contact an employee of @department_name@.\n\n"\
      "Your reservation number is @reservation_id@.\n\n"\
      "Thank you,\n"\
      "@department_name@\n\n"\

    overdue_checkin_email_body =
      "Dear @user@,\n\n"\
      "It looks like you have overdue equipment!\n\n"\
      "Please return the following equipment to us as soon as possible. Until then you will be charged a daily late fee of @late_fee@.\n\n"\
      "@equipment_list@\n\n"\
      "Failure to return equipment will result in the levying of replacement fees, and potential revocation of borrowing privileges.\n\n"\
      "Your reservation number is @reservation_id@.\n\n"\
      "Thank you,\n"\
      "@department_name@"

    deleted_missed_reservation_email_body =
      "Dear @user@,\n\n"\
      "Because you have missed a scheduled equipment checkout, your reservation (number @reservation_id@) has been cancelled. If you believe this is in error, please contact an administrator.\n\n"\
      "@equipment_list@\n\n"\
      "Thank you,\n"\
      "@department_name@"

    # Create initial application configs.

    if AppConfig.all.empty?
      puts ''
      puts 'Please enter the following information to configure your reservations'
      puts 'application:'

      while !AppConfig.first
        puts ''
        puts 'Site title (this will show across the top of the browser window when visiting'
        puts 'your site):'
        site_title = STDIN.gets.chomp
        puts 'Administrator Email (this email address will receive administrator'
        puts 'notifications from the application):'
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
            puts "Your application settings were not saved for the reasons listed below. Please"
            puts "double check that you're entering valid input for each item."
            puts e
          end
        end # transaction

        if AppConfig.first
          puts 'Congratulations! Your application has been setup successfully. We highly'
          puts 'recommend that you now visit the site using the administrator account that you'
          puts "just created, and finish setting up the configurations that we couldn't set"
          puts "from here. Thanks for using reservations, and don't hesitate to submit any"
          puts 'issues or questions on our github page:'
          puts 'https://github.com/YaleSTC/reservations'
        end
      end
    else
      puts 'Application configurations appear to already be set. You can edit application'
      puts 'configs by accessing the url ending in /app_configs from an admin account. If'
      puts 'you do wish to reset everything, you can run the rake task'
      puts '$bundle exec rake db:migrate:reset, which will delete your database completely'
      puts 'and build a new one. After running that command, please remember to run this'
      puts 'script again.'
    end
  end
end

