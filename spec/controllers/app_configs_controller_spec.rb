require 'spec_helper'

# Routes:
#
# match '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
# resources :app_configs, :only => [:update]
#
# match '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
# match '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs


describe AppConfigsController do

  describe 'GET edit' do
    context 'app_config exists already' do
      before(:each) do
        @app_config = FactoryGirl.create(:app_config)
      end
      context 'user is admin' do
        before(:each) do
          controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
          get :edit
        end
        it { should render_template(:edit) }
        it { should respond_with(:success) }
        it { should_not set_the_flash }
        it 'should assign @app_config variable to the first appconfig in the db' do
          expect(assigns(:app_config)).to eq(AppConfig.first)
        end
      end
      context 'user is not admin' do
        before(:each) do
          controller.stub(:current_user).and_return(FactoryGirl.create(:user))
          get :edit
        end
        it { should redirect_to(root_path) }
      end
    end
    context 'app_config does not exist yet' do
      before(:each) do
        get :edit
      end
      it { should respond_with(:success) }
      it { should set_the_flash }
      it { should render_template(%w(layouts/application application_setup/index)) }
    end
  end

  describe 'POST update' do
    context 'app config already exists' do
      before(:each) do
        @app_config = FactoryGirl.create(:app_config)
      end
      context 'user is admin' do
        before (:each) do
          controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
          @params = FactoryGirl.attributes_for(:app_config) # Except paperclip attributes that trigger MassAssignment errors
            .reject {|k,v| [:favicon_file_name, :favicon_content_type, :favicon_file_size, :favicon_updated_at].include? k}
        end

        it 'assigns current configuration to @app_config' do
          post :update, app_config: @params
          expect(assigns(:app_config)).to eq(@app_config)
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
      context 'user is not admin' do
        before(:each) do
          controller.stub(:current_user).and_return(FactoryGirl.create(:user))
          post :update
        end
        it { should redirect_to(root_path) }
      end
    end
    context 'app_config does not exist yet' do
      before(:each) do
        post :update
      end
      it { should respond_with(:success) }
      it { should set_the_flash }
      it { should render_template(%w(layouts/application application_setup/index)) }
    end
  end
end