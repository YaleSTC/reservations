# frozen_string_literal: true
require 'spec_helper'

describe ReportsController, type: :controller do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @banned = FactoryGirl.create(:banned)
    @checkout_person = FactoryGirl.create(:checkout_person)
    @admin = FactoryGirl.create(:admin)
  end

  context 'as admin user' do
    before(:each) do
      mock_app_config
      sign_in @admin
    end

    describe 'PUT /reports/update' do
      it 'defaults to the past year without a session or params' do
        get :index # set @start_date and @end_date
        put :update_dates, format: :js

        expect(assigns(:start_date)).to eq(Time.zone.today - 1.year)
        expect(assigns(:end_date)).to eq(Time.zone.today)
      end

      it 'keeps the session values with no params' do
        # set @start_date and @end_date to session values
        get :index, nil, report_start_date: Time.zone.today - 2.days,
                         report_end_date: Time.zone.today - 1.day
        put :update_dates, { format: :js },
            report_start_date: Time.zone.today - 2.days,
            report_end_date: Time.zone.today - 1.day

        expect(assigns(:start_date)).to eq(Time.zone.today - 2.days)
        expect(assigns(:end_date)).to eq(Time.zone.today - 1.day)
      end

      it 'changes the dates and session with valid params' do
        # set @start_date and @end_date to session values
        get :index, nil, report_start_date: Time.zone.today - 2.days,
                         report_end_date: Time.zone.today - 1.day
        put :update_dates, { format: :js,
                             report: { start_date: Time.zone.today + 1.day,
                                       end_date: Time.zone.today + 2.days } },
            report_start_date: Time.zone.today - 2.days,
            report_end_date: Time.zone.today - 1.day

        expect(assigns(:start_date)).to eq(Time.zone.today + 1.day)
        expect(assigns(:end_date)).to eq(Time.zone.today + 2.days)
        expect(session[:report_start_date]).to eq(Time.zone.today + 1.day)
        expect(session[:report_end_date]).to eq(Time.zone.today + 2.days)
      end
    end
  end
end
