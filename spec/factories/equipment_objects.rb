# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  # Sequences defined in _sequences.rb

  factory :equipment_object do
    name 'name'
    serial
    equipment_model factory: :equipment_model
    deactivation_reason nil
    notes ''

    factory :deactivated do
      deactivation_reason 'Because I can'
      deleted_at '2013-01-01 00:00:00'
    end
  end
end
