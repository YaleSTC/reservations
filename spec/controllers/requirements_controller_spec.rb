require 'spec_helper'

describe RequirementsController do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    @controller.stub(:first_time_user).and_return(nil)
    @controller.stub(:require_admin).and_return(true)
    @requirement = FactoryGirl.create(:requirement, contact_name: "Adam Bray")
  end
  describe 'GET index' do
    before(:each) do
      get :index
    end
    it { should respond_with(:success) }
    it { should render_template(:index) }
    it { should_not set_the_flash }
    it 'should populate an array of all requirements' do
      expect(assigns(:requirements)).to eq([@requirement])
    end
  end
  describe 'GET show' do
    before(:each) do
      get :show, id: @requirement
    end
    it { should respond_with(:success) }
    it { should render_template(:show) }
    it { should_not set_the_flash }
    it 'should set @requirement to the selected requirement' do
      expect(assigns(:requirement)).to eq(@requirement)
    end
  end
  describe 'GET new' do
    before(:each) do
      get :new
    end
    it { should respond_with(:success) }
    it { should render_template(:new) }
    it { should_not set_the_flash }
    it 'assigns a new requirement to @requirement' do
      assigns(:requirement).should be_new_record
      assigns(:requirement).kind_of?(Requirement).should be_true
    end
  end
  describe 'GET edit' do
    before(:each) do
      get :edit, id: @requirement
    end
    it 'should set @requirement to the selected requirement' do
      expect(assigns(:requirement)).to eq(@requirement)
    end
    it { should respond_with(:success) }
    it { should render_template(:edit) }
    it { should_not set_the_flash }
  end
  describe 'PUT update' do
    context 'with valid attributes' do
      before(:each) do
        put :update, id: @requirement, requirement: FactoryGirl.attributes_for(:requirement, contact_name: "John Doe")
      end
      it 'should set @requirement to the correct requirement' do
        expect(assigns(:requirement)).to eq(@requirement)
      end
      it 'should update the attributes of @requirement' do
        @requirement.reload
        @requirement.contact_name.should == "John Doe"
      end
      it { should redirect_to(@requirement) }
      it { should set_the_flash }
    end
    context 'with invalid attributes' do
      before(:each) do
        put :update, id: @requirement, requirement: FactoryGirl.attributes_for(:requirement, contact_name: "")
      end
      it 'should not update the attributes of @requirement' do
        @requirement.reload
        @requirement.contact_name.should_not == ""
        @requirement.contact_name.should == "Adam Bray"
      end
      it { should render_template(:edit) }
      it { should_not set_the_flash }
    end
  end
  describe 'POST create' do
    context 'with valid attributes' do
      before(:each) do
        post :create, requirement: FactoryGirl.attributes_for(:requirement)
      end
      it 'saves a new requirement' do
        expect{
          post :create, requirement: FactoryGirl.attributes_for(:requirement)
        }.to change(Requirement,:count).by(1)
      end
      it { should redirect_to(Requirement.last) }
      it { should set_the_flash }
    end
    context 'with invalid attributes' do
      before(:each) do
        post :create, requirement: FactoryGirl.attributes_for(:requirement, contact_name: nil)
      end
      it 'fails to save a new requirment' do
        expect{
          post :create, requirement: FactoryGirl.attributes_for(:requirement, contact_name: nil)
        }.not_to change(Requirement,:count)
      end
      it { should_not set_the_flash }
      it { should render_template(:new) }
    end
  end
  describe 'DELETE destroy' do
    it 'assigns the selected requirement to @requirement' do
      delete :destroy, id: @requirement
      expect(assigns(:requirement)).to eq(@requirement)
    end
    it 'removes @requirement from the database' do
      expect{
          delete :destroy, id: @requirement
        }.to change(Requirement,:count).by(-1)
    end
    it 'should redirect to the requirements index page' do
      delete :destroy, id: @requirement
      response.should redirect_to requirements_url
    end
  end
  after(:all) do
    @app_config.destroy
  end
end
