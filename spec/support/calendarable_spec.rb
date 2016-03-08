require 'spec_helper'

shared_examples_for 'calendarable' do |model|
  before(:each) do
    sign_in FactoryGirl.create(:admin)
    @obj = FactoryGirl.create(model.to_s.underscore.to_sym)
    @res = send("gen_#{model.to_s.underscore}_res".to_sym, @obj)
    @res2 = send("gen_#{model.to_s.underscore}_res".to_sym)
  end

  context 'GET calendar' do
    before { get :calendar, id: @obj }

    it 'stores instance variables' do
      expect(assigns(:resource)).to eq(@obj)
      expect(assigns(:src_path)).to \
        eq("calendar_#{@obj.class.to_s.underscore}_path".to_sym)
    end
    it 'responds with HTML' do
      expect(response.content_type).to eq('text/html')
    end
  end

  context 'GET calendar dates' do
    it 'defaults to +/- 6 months' do
      get :calendar, id: @obj

      expect(assigns(:start_date)).to eq(Time.zone.today - 6.months)
      expect(assigns(:end_date)).to eq(Time.zone.today + 6.months)
    end

    it 'uses start and end' do
      start_date = Time.zone.today
      end_date = Time.zone.today + 1.day

      get :calendar, id: @obj, start: start_date, end: end_date

      expect(assigns(:start_date)).to eq(start_date)
      expect(assigns(:end_date)).to eq(end_date)
    end

    it 'uses calendar[start_date] and calendar[end_date]' do
      start_date = Time.zone.today
      end_date = Time.zone.today + 1.day

      get :calendar, id: @obj, calendar: { start_date: start_date,
                                           end_date: end_date }

      expect(assigns(:start_date)).to eq(start_date)
      expect(assigns(:end_date)).to eq(end_date)
    end
  end

  context 'GET calendar JSON' do
    before { get :calendar, format: :json, id: @obj }

    it 'stores reservations for the object correctly' do
      expect(assigns(:calendar_res)).to include(@res)
      expect(assigns(:calendar_res)).not_to include(@res2)
    end
    it 'stores other instance variables' do
      expect(assigns(:resource)).to eq(@obj)
      expect(assigns(:src_path)).to \
        eq("calendar_#{@obj.class.to_s.underscore}_path".to_sym)
    end
    it 'responds with JSON' do
      expect(response.content_type).to eq('application/json')
    end
  end

  context 'GET calendar ICS' do
    before { get :calendar, format: :ics, id: @obj }

    it 'stores reservations for the object correctly' do
      expect(assigns(:calendar_res)).to include(@res)
      expect(assigns(:calendar_res)).not_to include(@res2)
    end
    it 'stores other instance variables' do
      expect(assigns(:resource)).to eq(@obj)
      expect(assigns(:src_path)).to \
        eq("calendar_#{@obj.class.to_s.underscore}_path".to_sym)
    end

    it 'responds with ICS format' do
      expect(response.content_type).to eq('text/calendar')
    end
  end
end

def gen_user_res(user = nil)
  user ||= FactoryGirl.create(:user)
  gen_res(user)
end

def gen_category_res(cat = nil)
  cat ||= FactoryGirl.create(:category)

  gen_equipment_model_res(nil, cat)
end

def gen_equipment_model_res(em = nil, cat = nil)
  opts = cat ? { category: cat } : {}

  em ||= FactoryGirl.create(:equipment_model, opts)

  gen_equipment_item_res(nil, em)
end

def gen_equipment_item_res(ei = nil, em = nil)
  opts = em ? { equipment_model: em } : {}

  ei ||= FactoryGirl.create(:equipment_item, opts)

  gen_res(nil, ei)
end

def gen_res(user = nil, ei = nil)
  return if ei && ei.equipment_model.nil? # check for invalid ei

  ei ||= FactoryGirl.create(:equipment_item)
  user ||= FactoryGirl.create(:user)

  FactoryGirl.create(:valid_reservation, equipment_item: ei, reserver: user,
                                         equipment_model: ei.equipment_model)
end
