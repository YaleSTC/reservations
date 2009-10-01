require 'test_helper'

class EquipmentObjectTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert EquipmentObject.new.valid?
  end
end
