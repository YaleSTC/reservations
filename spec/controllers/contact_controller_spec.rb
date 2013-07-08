require 'spec_helper'

describe ContactController do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    @controller.stub(:first_time_user).and_return(nil)
    @category = FactoryGirl.create(:category)
    @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
  end
  describe 'GET new' do
    before(:each) do
      get :new
    end
    it 'should assign @message to a new message' do
      assigns(:message).should be_new_record
      assigns(:message).kind_of?(Message).should be_true
    end
    it { should respond_with(:success) }
    it { should render_template(:new) }
    it { should_not set_the_flash }
  end
  describe 'POST create' do
    before(:each) do
      ActionMailer::Base.deliveries = nil
    end
    context 'with valid attributes' do
      before(:each) do
        post :create, message: FactoryGirl.attributes_for(:message)
      end
      it 'sends a message' do
        ActionMailer::Base.deliveries.last.subject.should eq('[Reservations Specs] ' + FactoryGirl.build(:message).subject)
      end
      it { should redirect_to(root_path) }
      it { should set_the_flash }
    end
    context 'with invalid attributes' do
      before(:each) do
        post :create, message: FactoryGirl.attributes_for(:message, name: nil)
      end
      it { should render_template(:new) }
      it { should set_the_flash }
      it 'should not send a message' do
        ActionMailer::Base.deliveries.should eq([])
      end
    end
  end
  after(:all) do
    @app_config.destroy
  end
end
