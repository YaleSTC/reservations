require 'spec_helper'

describe UserMailerHelper, type: :helper do
  before(:each) do
    @app_configs = double(department_name: 'dept', terms_of_service: 'tos')
    @reservation = double(id: 1, reserver: double(name: 'name'),
                          equipment_model: double(name: 'em', late_fee: 100,
                                                  replacement_fee: 200),
                          start_date: Time.zone.today,
                          due_date: Time.zone.today + 1.day)
  end

  context '.replace_variables' do
    it 'returns an empty string when no body is passed' do
      expect(replace_variables(nil)).to eq('')
    end

    it 'replaces @user@ with the reserver name' do
      expect(replace_variables('@user@')).to eq(@reservation.reserver.name)
    end

    it 'replaces @reservation_id@ with the reservation id' do
      expect(replace_variables('@reservation_id@')).to eq(@reservation.id.to_s)
    end

    it 'replaces @department_name@ with the department name' do
      expect(replace_variables('@department_name@')).to \
        eq(@app_configs.department_name)
    end

    it 'replaces @equipment_list@ with the equipment model name' do
      expect(replace_variables('@equipment_list@')).to \
        eq(@reservation.equipment_model.name)
    end

    it 'replaces @return_date@ with the due date' do
      expect(replace_variables('@return_date@')).to \
        eq(@reservation.due_date.to_s(:long))
    end

    it 'replaces @start_date@ with the start date' do
      expect(replace_variables('@start_date@')).to \
        eq(@reservation.start_date.to_s(:long))
    end

    it 'replaces @late_fee@ with the equipment model late fee rate' do
      expect(replace_variables('@late_fee@')).to \
        eq(number_to_currency(@reservation.equipment_model.late_fee))
    end

    it 'replaces @replacement_fee@ with the equipment model replacement fee' do
      expect(replace_variables('@replacement_fee@')).to \
        eq(number_to_currency(@reservation.equipment_model.replacement_fee))
    end

    it 'replaces @tos@ with the terms of service' do
      expect(replace_variables('@tos@')).to eq(@app_configs.terms_of_service)
    end
  end
end
