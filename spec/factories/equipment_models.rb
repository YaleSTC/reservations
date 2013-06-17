# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_model do
    sequence(:name) {|n| "EquipmentModel#{n}"}
    description { Faker::HipsterIpsum.paragraph(4) }
    late_fee { r.rand(50.00..1000.00).round(2).to_d }
    replacement_fee { r.rand(50.00..1000.00).round(2).to_d }
    max_per_user { r.rand(1..40) }
    active true
    max_renewal_times { r.rand(0..40) }
    max_renewal_length { r.rand(0..40) }
    renewal_days_before_due { r.rand(0..9001) }
    category

    factory :equipment_model_with_object do
      after(:create) do |mod|
        FactoryGirl.create(:equipment_object, :equipment_model => mod)
      end
    end
  end
end