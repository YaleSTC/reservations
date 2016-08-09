# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')

class UserMock < Mocker
  def initialize(role = :user, traits: [], **attrs)
    attrs = FactoryGirl.attributes_for(role).merge attrs
    traits = [:findable] if traits.empty?
    super(traits: traits, **attrs)
  end

  def self.klass
    User
  end

  def self.klass_name
    'User'
  end
end
