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
      end
    end
  end



end
