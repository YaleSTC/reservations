# frozen_string_literal: true
module EquipmentItemGenerator
  def self.generate
    EquipmentItem.create! do |ei|
      ei.name = "Number #{(0...3).map { 65.+(rand(25)).chr }.join}" +
                rand(1..9001).to_s
      ei.serial = (0...8).map { 65.+(rand(25)).chr }.join
      ei.active = true
      ei.equipment_model_id = EquipmentModel.all.sample.id
      ei.notes = ''
    end
  end
end
