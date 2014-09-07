require 'spec_helper'

describe ContactController, :type => :controller do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    allow(@controller).to receive(:first_time_user).and_return(nil)
    @category = FactoryGirl.create(:category)
    allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
  end
  describe 'GET new' do
    before(:each) do
      get :new
    end
    it 'should assign @message to a new message' do
      expect(assigns(:message)).to be_new_record
      expect(assigns(:message).kind_of?(Message)).to be_truthy
    end
    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(:new) }
    it { is_expected.not_to set_the_flash }
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
        expect(ActionMailer::Base.deliveries.last.subject).to eq('[Reservations Specs] ' + FactoryGirl.build(:message).subject)
      end
      it { is_expected.to redirect_to(root_path) }
      it { is_expected.to set_the_flash }
    end
    context 'with invalid attributes' do
      before(:each) do
        post :create, message: FactoryGirl.attributes_for(:message, name: nil)
      end
      it { is_expected.to render_template(:new) }
      it { is_expected.to set_the_flash }
      it 'should not send a message' do
        expect(ActionMailer::Base.deliveries).to eq([])
      end
    end
  end
  after(:all) do
    @app_config.destroy
  end
end
