FactoryGirl.define do
  sequence :name do |n|
    "Name#{n}"
  end

  sequence :serial do |n|
    "FLKJDSF#{n}"
  end
end