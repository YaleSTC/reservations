# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')

class CartMock < Mocker
  def self.klass
    Cart
  end

  def self.klass_name
    'Cart'
  end
end
