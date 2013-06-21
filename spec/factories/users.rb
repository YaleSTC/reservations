# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user, aliases: [:beyonce] do
    id 1
    login "bgk1"
    first_name "Beyonce"
    last_name "Knowles"
    affiliation "Destiny's Child"
    email "beyonce.knowles@yale.edu"
    phone "555-555-5555"
    nickname "Sasha Fierce"
    terms_of_service_accepted true
    created_by_admin false
    adminmode nil
    checkoutpersonmode nil
    bannedmode nil
    normalusermode nil
    is_admin false
    is_checkout_person false
    is_banned false
  end

  factory :justin, class: User do
    id 2
    login "jrt4"
    first_name "Justin"
    last_name "Timberlake"
    affiliation "'N sync"
    email "justin.timberlake@yale.edu"
    phone "555-555-5555"
    terms_of_service_accepted true
  end

  factory :admin, parent: :user do
    is_admin true
  end

  factory :checkout_person, parent: :user do
    is_checkout_person true
  end

end
