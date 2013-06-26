# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :requirement do
    id { generate(:unique_id) }
    contact_name "Adam Bray"
    description "You must attend a training session with Adam before using this equipment."
    contact_info "adam.bray@yale.edu"
  end

  factory :another_requirement, class: Requirement do
  	contact_name "Austin Czarnecki"
  	description "You must attend a training session with Austin before using this equipment."
  	contact_info "austin.czarnecki@yale.edu"
  end
end
