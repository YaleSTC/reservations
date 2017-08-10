# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClassFromString do
  shared_examples 'valid class' do |method, string, klass|
    it 'returns a model class' do
      expect(described_class.send(method, string)).to eq(klass)
    end
  end

  shared_examples 'invalid class' do |method, string|
    it 'returns a model class' do
      expect { described_class.send(method, string) }.to raise_error(KeyError)
    end
  end

  REPORTS = { 'equipment_model' => EquipmentModel,
              'category' => Category,
              'user' => User,
              'equipment_item' => EquipmentItem }.freeze

  EQUIPMENT = { 'equipment_items' => EquipmentItem,
                'equipment_models' => EquipmentModel,
                'categories' => Category }.freeze

  describe '.reports!' do
    REPORTS.each { |k, v| it_behaves_like 'valid class', :reports!, k, v }
    it_behaves_like 'invalid class', :reports!, 'logger'
  end

  describe '.equipment!' do
    EQUIPMENT.each { |k, v| it_behaves_like 'valid class', :equipment!, k, v }
    it_behaves_like 'invalid class', :equipment!, 'logger'
  end
end
