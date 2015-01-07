require 'spec_helper'

describe Report, type: :model do
  before(:each) do
    @report = Report.new
  end

  describe Column do
    it 'can be constructed from arrays' do
      column = Column.arr_to_col ['Name', :scope, :type, :field]
      expect(column.name).to eq('Name')
      expect(column.filter).to eq(:scope)
      expect(column.data_type).to eq(:type)
      expect(column.data_field).to eq(:field)
    end
  end
  describe Row do
    it 'can be constructed from Equipment Models' do
      em = FactoryGirl.build(:equipment_model)
      row = Row.item_to_row em
      expect(row.name).to eq(em.name)
      expect(row.item_id).to eq(em.id)
      expect(row.link_path).to eq(Rails.application.routes.url_helpers
                                  .subreport_path(id: em.id, 
                                                  class: 'equipment_model'))
    end
    it 'can be constructed from Reservations' do
      u = FactoryGirl.build(:reservation)
      row = Row.item_to_row u
      expect(row.name).to eq(u.id)
      expect(row.item_id).to eq(u.id)
      expect(row.link_path).to eq(Rails.application.routes.url_helpers
                                  .reservation_path(id: u.id))
    end
  end

  describe '.average2' do
    it 'returns N/A for arrays of size 0' do
      expect(Report.average2 []).to eq('N/A')
    end
    it 'returns N/A for arrays consisting of nil' do
      expect(Report.average2 [nil, nil]).to eq('N/A')
    end
    it 'calculates averages correctly' do
      expect(Report.average2 [1,2,3]).to eq(2)
    end
    it 'throws out nils' do
      expect(Report.average2 [1,2,3,nil]).to eq(2)
    end
    it 'rounds to 2 decimal places' do
      expect(Report.average2 [0.12, 1.799, 4.3]).to eq(2.07)
    end
  end

  describe '.get_class' do
    it 'converts equipment_object_id to EquipmentObject' do
      expect(Report.get_class(:equipment_object_id)).to eq (EquipmentObject)
    end
    it 'works on :reserver_id' do
      expect(Report.get_class(:reserver_id)).to eq(User)
    end
    it 'returns Reservation when given :id' do
      expect(Report.get_class(:id)).to eq(Reservation)
    end
  end

  describe '.build_new' do
    before(:each) do
      @id = :equipment_object_id
      @report = Report.build_new(@id)
    end
    it 'returns a report object' do
      expect(@report.class).to eq(Report)
    end
    it 'sets the row_item_type' do
      expect(@report.row_item_type).to eq(@id)
    end
  end
end
