# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')

class RequirementMock < Mocker
  def self.klass
    Requirement
  end

  def self.klass_name
    'Requirement'
  end
end
