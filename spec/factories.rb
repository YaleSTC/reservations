FactoryGirl.define do

  factory :user do
    sequence(:login) {|n| "netid#{n}" }
    first_name {Faker::Name.first_name}
    last_name  {Faker::Name.last_name}
    phone "1234567890"
    email {"#{first_name}.#{last_name}@yale.edu"}
    affiliation "YC"
    adminmode false

    factory :admin do
      adminmode true
    end
  end

end
