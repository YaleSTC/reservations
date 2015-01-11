require 'spec_helper'

describe Report, type: :model do
  before(:each) do
    @report = Report.new
  end

  describe Report::Column do
    it 'can be constructed from arrays' do
      column = Report::Column.arr_to_col ['Name', :scope, :type, :field]
      expect(column.name).to eq('Name')
      expect(column.filter).to eq(:scope)
      expect(column.data_type).to eq(:type)
      expect(column.data_field).to eq(:field)
    end
  end
  describe Report::Row do
    it 'can be constructed from Equipment Models' do
      em = FactoryGirl.create(:equipment_model)
      row = Report::Row.item_to_row em
      expect(row.name).to eq(em.name)
      expect(row.item_id).to eq(em.id)
      expect(row.link_path).to eq(Rails.application.routes.url_helpers
                                  .subreport_path(id: em.id,
                                                  class: 'equipment_model'))
    end
    it 'can be constructed from Reservations' do
      u = FactoryGirl.build(:reservation)
      u.save(validate: false)
      row = Report::Row.item_to_row u
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
      expect(Report.average2 [1, 2, 3]).to eq(2)
    end
    it 'throws out nils' do
      expect(Report.average2 [1, 2, 3, nil]).to eq(2)
    end
    it 'rounds to 2 decimal places' do
      expect(Report.average2 [0.12, 1.799, 4.3]).to eq(2.07)
    end
  end

  describe '.get_class' do
    it 'converts equipment_object_id to EquipmentObject' do
      expect(Report.get_class(:equipment_object_id)).to eq(EquipmentObject)
    end
    it 'works on :reserver_id' do
      expect(Report.get_class(:reserver_id)).to eq(User)
    end
    it 'returns Reservation when given :id' do
      expect(Report.get_class(:id)).to eq(Reservation)
    end
  end

  describe '.build_new' do
    DEFAULT_COLUMNS = [['Total', :all, :count],
                       ['Reserved', :reserved, :count],
                       ['Checked Out', :checked_out, :count],
                       ['Overdue', :overdue, :count],
                       ['Returned On Time', :returned_on_time, :count],
                       ['Returned Overdue', :returned_overdue, :count],
                       ['User Count', :all, :count, :reserver_id]]
    before(:each) do
      @id = :equipment_object_id
      @class = EquipmentObject
      @report = Report.build_new(@id)
    end
    it 'returns a report object' do
      expect(@report.class).to eq(Report)
    end
    it 'sets the row_item_type' do
      expect(@report.row_item_type).to eq(@id)
    end
    it 'has the correctly headed columns' do
      @report.columns.each_with_index do |col, i|
        col.name = DEFAULT_COLUMNS[i][0]
        col.filter = DEFAULT_COLUMNS[i][1]
        col.data_type = DEFAULT_COLUMNS[i][2]
        col.data_field = DEFAULT_COLUMNS[i][3]
      end
    end
    it 's columns res_sets have the correct number of elements' do
      @report.columns.each_with_index do |col, _i|
        expect(col.res_set.count).to eq Reservation.send(col.filter).count
      end
    end
    it 's columns res_sets are of type array' do
      # important that they're not AR:Relation for speed purposes
      @report.columns.each do |col|
        expect(col.res_set.class).to eq Array
      end
    end
    it 's columns res_sets are just ids under the right circumstances' do
      @report.columns.each_with_index do |col, _i|
        next unless col.data_field.nil? && col.data_type == :count
        expect(col.res_set).to eq(Reservation.send(col.filter)
                                  .collect(&@id))
      end
    end
    it 'has the correctly headed rows' do
      items = @class.all
      items.each do |item|
        expect(@report.rows).to include?(Report::Row.item_to_row item)
      end
    end
  end
end
