require 'spec_helper'

# Routes:
#
# match '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
# resources :app_configs, :only => [:update]
#
# match '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
# match '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs


describe AppConfigsController, focus: true do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
  end
  context 'User is not admin' do
    before (:each) do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
    end

    describe 'GET edit' do
      it "redirects non-admin away" do
        get :edit
      end
    end

    describe 'POST update' do
      it "redirects non-admin away" do
        post :update
      end
    end

    after(:each) do
      response.should redirect_to(root_path)
    end
  end

  context 'User is admin' do
    before (:each) do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end

    describe 'GET edit' do
      before (:each) do
        get :edit
      end

      context 'There is some existing AppConfig' do
        it 'assigns current configuration to @app_config' do
          @app_config = FactoryGirl.create(:app_config)
          get :edit
          expect(assigns(:app_config)).to eq(AppConfig.first)
        end
        it { should respond_with(:success) }
        it { should render_template(:edit) }
        it { should_not set_the_flash }
      end
    end

    describe 'POST update' do
      before (:each) do
        @app_config = FactoryGirl.create(:app_config)
        @params = FactoryGirl.attributes_for(:app_config) # Except paperclip attributes that trigger MassAssignment errors
          .reject {|k,v| [:favicon_file_name, :favicon_content_type, :favicon_file_size, :favicon_updated_at].include? k}
      end

      it 'assigns current configuration to @app_config' do
        post :update, app_config: @params
        expect(assigns(:app_config)).to eq(AppConfig.first)
      end

      # TODO: FIXME
      context 'With valid parameters' do
        # TODO: Simulate successful ActiveRecord update_attributes call
        it 'resets TOS status for all users when :reset_tos_for_users is 1'
        it 'maintains TOS status for all users when :reset_tos_for_users is not 1'
        it 'restores favicon when appropriate'
        # it { should respond_with(:success) }
        # it { should redirect_to(catalog_path) }
      end

      context 'With invalid parameters' do
        # TODO: Simulate update_attributes failure
        before (:each) do
          @params = FactoryGirl.attributes_for(:app_config, site_title: nil) # Except paperclip attributes that trigger MassAssignment errors
            .reject {|k,v| [:favicon_file_name, :favicon_content_type, :favicon_file_size, :favicon_updated_at].include? k}
          post :update, @params
        end
        # it { should render_template(:edit) }
      end
    end
  end
end