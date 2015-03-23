# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :username do |n|
    "abc#{n}"
  end

  factory :user, aliases: [:reserver, :checkout_handler, :checkin_handler] do
    sequence(:cas_login) { |n| "netid#{n}" }
    first_name 'First'
    last_name 'Last'
    affiliation 'Yale'
    email { "#{cas_login}@example.edu".downcase }
    phone '555-555-5555'
    terms_of_service_accepted true
    created_by_admin false
    role 'normal'
    view_mode 'normal'

    if ENV['CAS_AUTH']
      username { cas_login }
    else
      username { email }
      password 'passw0rd'
      password_confirmation 'passw0rd'
    end

    factory :admin do
      role 'admin'
      view_mode 'admin'
    end

    factory :checkout_person do
      role 'checkout'
      view_mode 'checkout'
    end

    factory :banned do
      role 'banned'
      view_mode 'banned'
    end

    factory :guest do
      role 'guest'
      view_mode 'guest'
    end

    factory :no_phone do
      phone ''
    end
  end
end
