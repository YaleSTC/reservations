# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :app_config do
    site_title "Reservations Specs"
    admin_email "admin.email@spec.com"
  end
end
