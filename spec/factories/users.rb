# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence :login do |n|
    "abc#{n}"
  end

  factory :user, aliases: [:reserver, :checkout_handler, :checkin_handler] do
    sequence(:login) { |n| "netid#{n}" }
    first_name "First"
    last_name "Last"
    affiliation "Yale"
    email { "#{first_name}.#{last_name}@yale.edu".downcase }
    phone "555-555-5555"
    terms_of_service_accepted true
    created_by_admin false
    role 'normal'
    view_mode 'normal'

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

    factory :no_phone do
      phone ''
    end
  end
end
