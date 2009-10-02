require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Document.new.valid?
  end
end
