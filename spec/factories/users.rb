# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence :login do |n|
    "abc#{n}"
  end

  trait :default_user_characteristics do
    adminmode nil
    checkoutpersonmode nil
    bannedmode nil
    normalusermode nil
    is_admin false
    is_checkout_person false
    is_banned false
  end

  factory :user, aliases: [:reserver, :checkout_handler, :checkin_handler], traits: [:default_user_characteristics] do
    sequence(:login) { |n| "netid#{n}" }
    first_name "First"
    last_name "Last"
    affiliation "Yale"
    email { "#{first_name}.#{last_name}@yale.edu".downcase }
    phone "555-555-5555"
    terms_of_service_accepted true
    created_by_admin false

    factory :deactivated_user do
      deleted_at "2013-01-01 00:00:00"
    end

    factory :admin do
      is_admin true
    end

    factory :checkout_person do
      is_checkout_person true
    end
  end
end