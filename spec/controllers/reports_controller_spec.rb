require 'spec_helper'

MODEL_COLUMNS = [['Total', :all, :count],
                 ['Reserved', :reserved, :count],
                 ['Checked Out', :checked_out, :count],
                 ['Overdue', :overdue, :count],
                 ['Returned On Time', :returned_on_time, :count],
                 ['Returned Overdue', :returned_overdue, :count],
                 ['Avg Planned Duration', :all, :duration],
                 ['Avg Time Checked Out', :all, :time_checked_out]
                ]
RES_COLUMNS = [['Reserver', :all, :name, :reserver],
               ['Equipment Model', :all, :name, :equipment_model],
               ['Equipment Object', :all, :name, :equipment_object],
               ['Status', :all, :display, :status],
               ['Start Date', :all, :display, :start_date],
               ['Checked Out', :all, :display, :checked_out],
               ['Due Date', :all, :display, :due_date],
               ['Checked In', :all, :display, :checked_in]]

describe ReportsController, type: :controller do
  context 'with admin user' do
    before do
      @app_config = FactoryGirl.create(:app_config)

      sign_in FactoryGirl.create(:admin)
    end
    describe 'GET index' do
      before { get :index }
      it { is_expected.to render_template(:index) }
      it 'builds the tables correctly' do
        reservations = Reservation.starts_on_days(assigns(:start_date),
                                                  assigns(:end_date))
        expect(Report).to receive(:build_new).with(:equipment_model_id,
                                                   reservations)
        expect(Report).to receive(:build_new).with(:category_id, reservations)
        get :index
      end
    end
    describe 'GET subreport' do
      before(:all) do
        FactoryGirl.create(:equipment_model)
      end
      before do
        get :subreport, class: 'equipment_model', id: 1
      end
      it { is_expected.to render_template(:subreport) }
      it 'builds the proper subreports' do
        reservations = Reservation.starts_on_days(assigns(:start_date),
                                                  assigns(:end_date))
                       .where(equipment_model_id: 1)
        expect(Report).to receive(:build_new).with(:equipment_model_id,
                                                   reservations, MODEL_COLUMNS)
        expect(Report).to receive(:build_new).with(:equipment_object_id,
                                                   reservations, MODEL_COLUMNS)
        expect(Report).to receive(:build_new).with(:reserver_id,
                                                   reservations, MODEL_COLUMNS)
        expect(Report).to receive(:build_new).with(:id,
                                                   reservations, RES_COLUMNS)
        get :subreport, class: 'equipment_model', id: 1
      end
    end
  end
end
