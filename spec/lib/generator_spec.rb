# frozen_string_literal: true

require 'spec_helper'

describe Generator do
  OBJECTS = %i[app_config category requirement user superuser].freeze
  shared_examples 'generates a valid' do |method|
    it method.to_s do
      expect(Generator.send(method)).to be_truthy
    end
  end
  OBJECTS.each { |o| it_behaves_like 'generates a valid', o }

  context 'blackout generation' do
    before { Generator.user }
    it_behaves_like 'generates a valid', :blackout
  end
  context 'equipment_model generation' do
    before { Generator.category }
    it_behaves_like 'generates a valid', :equipment_model
  end

  context 'requiring a category and equipment model' do
    before do
      Generator.category
      Generator.equipment_model
    end
    it_behaves_like 'generates a valid', :equipment_item
    it_behaves_like 'generates a valid', :checkout_procedure
    it_behaves_like 'generates a valid', :checkin_procedure
  end

  context 'reservation generation' do
    before do
      Generator.category
      Generator.user
      Generator.superuser
      Generator.equipment_model
      Generator.equipment_item
    end
    it_behaves_like 'generates a valid', :reservation
  end

  describe 'generate' do
    it 'creates the specified number of objects' do
      object = :user
      expect(Generator).to receive(object).exactly(5).times
      Generator.generate(object.to_s, 5)
    end
  end
end
