require 'spec_helper'

shared_examples_for 'page success' do
  it { should respond_with(:success) }
  it { should_not set_the_flash }
end

describe BlackoutsController do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before {
    @controller.stub(:first_time_user).and_return(:nil)
  }
  let!(:object) {
    FactoryGirl.create(:blackout)
  }

  describe 'with admin' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end
    context 'GET index' do
      before do
        get:index
      end
      it_behaves_like 'page success'
      it { should render_template(:index) }
      it 'should assign @blackouts to all blackouts' do
        assigns(:blackouts).include?(object).should be_true
      end
    end
    context 'GET show' do
      before do
        get :show, id: object
      end
      it_behaves_like 'page success'
      it { should render_template(:show) }
      context 'single blackout' do
        it 'should not display a set' do
          expect(assigns(:blackout_set) == nil)
        end
      end
      context 'recurring blackout' do
        let!(:obj_in_set) { FactoryGirl.create(:blackout_in_set) }
        #get :show, id: obj_in_set
        #it 'should display a set' do
        #  assigns(:blackout_set).include?(obj_in_set).should be_true
        #end
        # the above code doesn't work; i'm too much of an rspec newbie
      end
    end
    context 'GET new' do
      before do
        get :new
      end
      it_behaves_like 'page success'
      it { should render_template(:new) }
    end
    context 'GET new_recurring' do
      before do
        get :new_recurring
      end
      it_behaves_like 'page success'
      it { should render_template(:new_recurring) }
    end
    context 'GET edit' do
      before do
        get :edit, id: object
      end
      it_behaves_like 'page success'
      it { should render_template(:edit) }
    end
    context 'POST create_recurring' do
      context 'with correct params' do
        before do
          param_hash = FactoryGirl.attributes_for(:blackout_in_set)
          param_hash[:start_date] = '06/06/2014'
          param_hash[:end_date] = '06/07/2014'
          post :create_recurring, blackout: param_hash
        end
      end

      it { should redirect_to(:index) }
    end
    context 'POST create' do
      context 'with correct params' do
        before do
          post :create, blackout: FactoryGirl.attributes_for(:blackout)
        end
        it { should redirect_to(:index) }
      end
    end
    context 'PUT update' do
      before do
        put :update
      end
    end
    context 'DELETE destroy' do

    end
    context 'DELETE destroy recurring' do

    end
  end
  context 'is not admin' do
    context 'GET index' do
    end

  end
end
