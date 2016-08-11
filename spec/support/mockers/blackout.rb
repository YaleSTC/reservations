# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')

class BlackoutMock < Mocker
  def self.klass
    Blackout
  end

  def self.klass_name
    'Blackout'
  end
end
