# frozen_string_literal: true

# Class for parsing strings into class names
# Used in controllers to prevent SQL injection and other attacks
class ClassFromString
  REPORTS = { 'equipment_model' => EquipmentModel,
              'category' => Category,
              'user' => User,
              'equipment_item' => EquipmentItem }.freeze

  EQUIPMENT = { 'equipment_items' => EquipmentItem,
                'equipment_models' => EquipmentModel,
                'categories' => Category }.freeze

  def self.reports!(string)
    parse(REPORTS, string)
  end

  def self.equipment!(string)
    parse(EQUIPMENT, string)
  end

  def self.parse(hash, string)
    hash.fetch(string)
  end

  private_class_method :parse
end
