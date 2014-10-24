require 'spec_helper'

# Routes:
#
# match '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
# resources :app_configs, :only => [:update]
#
# match '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
# match '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs


describe AppConfigsController, :type => :controller do

  describe 'GET edit' do
    context 'app_config exists already' do
      before(:each) do
        @app_config = FactoryGirl.create(:app_config)
      end
      context 'user is admin' do
        before(:each) do
          sign_in FactoryGirl.create(:admin)
          get :edit
        end
        it { is_expected.to render_template(:edit) }
        it { is_expected.to respond_with(:success) }
        it { is_expected.not_to set_the_flash }
        it 'should assign @app_config variable to the first appconfig in the db' do
          expect(assigns(:app_config)).to eq(AppConfig.first)
        end
      end
      context 'user is not admin' do
        before(:each) do
          sign_in FactoryGirl.create(:user)
          get :edit
        end
        it { is_expected.to redirect_to(root_path) }
      end
    end
    context 'app_config does not exist yet' do
      before(:each) do
        sign_in FactoryGirl.create(:user)
        get :edit
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to set_the_flash }
      it { is_expected.to render_template('application_setup/index') }
    end
  end

  describe 'POST update' do
    context 'app config already exists' do
      before(:each) do
        AppConfig.destroy_all
        @app_config = FactoryGirl.create(:app_config)
      end
      context 'user is admin' do
        before (:each) do
          sign_in FactoryGirl.create(:admin)
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
          it 'resets TOS status for all users when :reset_tos_for_users is 1' do
            @user = FactoryGirl.create(:user)
            @params = @params.merge({reset_tos_for_users: 1})
            Rails.logger.debug @params
            post :update, app_config: @params
            @user.reload
            expect(@user.terms_of_service_accepted).to be_falsey
          end

          it 'maintains TOS status for all users when :reset_tos_for_users is not 1' do
            @user = FactoryGirl.create(:user)
            @params = @params.merge({reset_tos_for_users: 0})
            Rails.logger.debug @params
            post :update, app_config: @params
            @user.reload
            expect(@user.terms_of_service_accepted).to be_truthy
          end

          it 'correctly sets missing_phone flag for users when toggling :require_phone' do
            @user = FactoryGirl.create(:no_phone)
            expect(@user.missing_phone).to be_falsey
            @params = @params.merge({require_phone: 1})
            Rails.logger.debug @params
            post :update, app_config: @params
            @user.reload
            expect(@user.missing_phone).to be_truthy
          end

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
          sign_in FactoryGirl.create(:user)
          post :update
        end
        it { is_expected.to redirect_to(root_path) }
      end
    end
    context 'app_config does not exist yet' do
      before(:all) do
        AppConfig.destroy_all
      end
      before(:each) do
        sign_in FactoryGirl.create(:user)
        post :update
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to set_the_flash }
      it { is_expected.to render_template('application_setup/index') }
    end
  end
end
