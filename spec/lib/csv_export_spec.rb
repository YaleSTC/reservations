require 'spec_helper'
include CsvExport

describe CsvExport do
  before(:all) { FactoryGirl.create(:app_config) }

  MODELS = [:user, :category, :equipment_model, :equipment_item]
  PROTECTED_COLS = %w(id encrypted_password reset_password_token
                      reset_password_sent_at)

  shared_examples 'builds a csv' do |model|
    let(:csv) do
      generate_csv(FactoryGirl.build_list(model, 5)).split("\n")
    end

    it 'has the appropriate length' do
      expect(csv.size).to eq(6)
    end

    it 'has the appropriate columns' do
      expect(csv.first.split(',')).to eq(
        FactoryGirl.build(model).attributes.keys - PROTECTED_COLS)
    end

    it "doesn't include protected columns" do
      PROTECTED_COLS.each do |col|
        expect(csv.first.split(',')).not_to include(col)
      end
    end

    it 'limits columns appropriately' do
      cols = FactoryGirl.build(model).attributes.keys.sample(4)
      cols.delete 'id' if cols.include? 'id'
      csv = generate_csv(FactoryGirl.build_list(model, 5), cols).split("\n")
      expect(csv.first.split(',')).to eq(cols)
    end
  end

  MODELS.each { |m| it_behaves_like 'builds a csv', m }
end
