# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :user, aliases: [:reserver, :checkout_handler, :checkin_handler] do
    login "netid"
    first_name "First"
    last_name "Name"
    phone "1234567890"
    email { "#{first_name}.#{last_name}@yale.edu".downcase }
    affiliation "YC"
    adminmode false
    terms_of_service_accepted true

    factory :admin do
    	login "adid"
      first_name "Admin"
      last_name "Strator"
      adminmode true
    end
  end
end