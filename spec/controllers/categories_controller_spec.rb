require 'spec_helper'

describe CategoriesController, :type => :controller do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    allow(@controller).to receive(:first_time_user).and_return(nil)
    @category = FactoryGirl.create(:category)
  end
  describe 'GET index' do
    before(:each) do
      @inactive_category = FactoryGirl.create(:category, deleted_at: Date.current - 1)
    end
    context 'user is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
        get :index
      end
      it 'should populate an array of all categories if show deleted is true' do
        get :index, show_deleted: true
        expect(assigns(:categories)).to eq([@category, @inactive_category])
      end
      it 'should populate an array of active categories if show deleted is nil or false' do
        expect(assigns(:categories)).to eq([@category])
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:index) }
      it { is_expected.not_to set_the_flash }
    end
    context 'user is not admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
        get :index
      end
      it { is_expected.to redirect_to(root_url) }
      it { is_expected.to set_the_flash }
    end
  end
  describe 'GET show' do
    context 'user is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
        get :show, id: @category
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:show) }
      it { is_expected.not_to set_the_flash }
      it 'should set @category to the selected category' do
        expect(assigns(:category)).to eq(@category)
      end
    end
    context 'user is not admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
        get :show, id: @category
      end
      it { is_expected.to redirect_to(root_url) }
      it { is_expected.to set_the_flash }
    end
  end
  # all methods below should redirect to root_url if user is not an admin
  describe 'GET new' do
    context 'is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
        get :new
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:new) }
      it { is_expected.not_to set_the_flash }
      it 'assigns a new category to @category' do
        expect(assigns(:category)).to be_new_record
        expect(assigns(:category).kind_of?(Category)).to be_truthy
      end
    end
    context 'not admin' do
      it 'should redirect to root_url' do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
        get :new
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'POST create' do
    context 'is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
      end
      context 'with valid attributes' do
        before(:each) do
          post :create, category: FactoryGirl.attributes_for(:category)
        end
        it 'saves a new category to the database' do
          expect{
            post :create, category: FactoryGirl.attributes_for(:category)
          }.to change(Category,:count).by(1)
        end
        it { is_expected.to redirect_to(Category.last) }
        it { is_expected.to set_the_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          post :create, category: FactoryGirl.attributes_for(:category, name: nil)
        end
        it 'fails to save a new category' do
          expect{
            post :create, category: FactoryGirl.attributes_for(:category, name: nil)
          }.not_to change(Category, :count)
        end
        it { is_expected.to set_the_flash }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'not admin' do
      it 'should redirect to root url' do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
        post :create, category: FactoryGirl.attributes_for(:category)
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'GET edit' do
    context 'is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
        get :edit, id: @category
      end
      it 'should set @category to the selected category' do
        expect(assigns(:category)).to eq(@category)
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:edit) }
      it { is_expected.not_to set_the_flash }
    end
    context 'not admin' do
      it 'should redirect to root_url' do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:user))
        get :edit, id: @category
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'PUT update' do
    context 'is admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(FactoryGirl.create(:admin))
      end
      context 'with valid attributes' do
        before(:each) do
          put :update, id: @category, category: FactoryGirl.attributes_for(:category, name: "Updated")
        end
        it 'should set @category to the correct category' do
          expect(assigns(:category)).to eq(@category)
        end
        it 'should successfully save new attributes to the database' do
          @category.reload
          expect(@category.name).to eq("Updated")
        end
        it { is_expected.to redirect_to(@category) }
        it { is_expected.to set_the_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          put :update, id: @category, category: FactoryGirl.attributes_for(:category, name: nil, max_per_user: 10)
        end
        it 'should not update attributes of @category in the database' do
          @category.reload
          expect(@category.name).not_to be_nil
          expect(@category.max_per_user).not_to eq(10)
        end
        it { is_expected.to render_template(:edit) }
        it { is_expected.not_to set_the_flash }
      end
    end
  end
  after(:all) do
    @app_config.destroy
  end
end
