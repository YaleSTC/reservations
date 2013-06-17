# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :user do
    sequence(:login) {|n| "netid#{n}" }
    sequence(:first_name) {|n| "First#{n}"}
    sequence(:last_name) {|n| "Last#{n}"}
    phone "1234567890"
    email {"#{first_name}.#{last_name}@yale.edu"}
    affiliation "YC"
    adminmode false
    terms_of_service_accepted true

    factory :admin do
    	sequence(:login) {|n| "adid#{n}"}
      sequence(:first_name) {|n| "Admin#{n}"}
      sequence(:last_name) {|n| "Strator#{n}"}
      adminmode true
    end
  end
end