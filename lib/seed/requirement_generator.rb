# frozen_string_literal: true
module RequirementGenerator
  def self.generate
    Requirement.create! do |req|
      req.equipment_models = EquipmentModel.all.sample(rand(1..3))
      req.contact_name = FFaker::Name.name
      req.contact_info = FFaker::PhoneNumber.short_phone_number
      req.notes = FFaker::HipsterIpsum.paragraph(4)
      req.description = FFaker::HipsterIpsum.sentence
    end
  end
end
