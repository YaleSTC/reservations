require 'test_helper'

class EquipmentModelTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert EquipmentModel.new.valid?
  end
end
