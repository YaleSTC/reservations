# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    login "bgk1"
    first_name "Beyonce"
    last_name "Knowles"
    affiliation "Destiny's Child"
    email "beyonce.knowles@yale.edu"
    phone "555-555-5555"
    nickname "Sasha Fierce"
    terms_of_service_accepted true
    created_by_admin false
  end
end
