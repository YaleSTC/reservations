# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    # this is to ensure that all before_actions are run
    @first_user = FactoryGirl.create(:user)
    allow(controller).to receive(:app_setup_check)
    allow(controller).to receive(:load_configs)
    allow(controller).to receive(:seen_app_configs)
    allow(controller).to receive(:cart)
    allow(controller).to receive(:fix_cart_date)
    allow(controller).to receive(:set_view_mode)
    allow(controller).to receive(:make_cart_compatible)
    sign_in FactoryGirl.create(:user)
  end

  # TODO: This may involve rewriting the method somewhat
  describe 'PUT reload_catalog_cart' do
    before(:each) do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @first_user.id
      session[:cart].start_date = (Time.zone.today + 1.day)
      session[:cart].due_date = (Time.zone.today + 2.days)

      equipment_model =
        FactoryGirl.create(:equipment_model,
                           category: FactoryGirl.create(:category))
      FactoryGirl.create(:equipment_item,
                         equipment_model_id: equipment_model.id)
      session[:cart].add_item(equipment_model)
      @new_reserver = FactoryGirl.create(:user)
    end

    context 'valid parameters' do
      it 'should update cart dates' do
        new_start = Time.zone.today + 3.days
        new_end = Time.zone.today + 4.days

        put :reload_catalog_cart, params: { cart: { start_date_cart: new_start,
                                                    due_date_cart: new_end },
                                            reserver_id: @new_reserver.id }

        expect(session[:cart].start_date).to eq(new_start)
        expect(session[:cart].due_date).to eq(new_end)
        expect(session[:cart].reserver_id).to eq(@new_reserver.id.to_s)
      end

      it 'should not set the flash' do
        expect(flash).to be_empty
      end
    end

    context 'invalid parameters' do
      it 'should set the flash' do
        new_start = Time.zone.today - 300.days
        new_end = Time.zone.today + 4000.days

        put :reload_catalog_cart,
            params: { cart: { start_date_cart: new_start.strftime('%m/%d/%Y'),
                              due_date_cart: new_end.strftime('%m/%d/%Y') },
                      reserver_id: @new_reserver.id }

        expect(flash).not_to be_empty
      end
    end

    context 'banned reserver' do
      it 'should set the flash' do
        put :reload_catalog_cart,
            params: { cart: { start_date_cart: Time.zone.today,
                              due_date_cart: Time.zone.today + 1.day },
                      reserver_id: FactoryGirl.create(:banned).id }
        expect(flash[:error].strip).not_to eq('')
      end
    end
  end

  describe 'DELETE empty_cart' do
    before(:each) do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @first_user.id
      delete :empty_cart
    end
    it 'empties the cart' do
      expect(session[:cart].items).to be_empty
    end
    it { is_expected.to redirect_to(root_path) }
    it { is_expected.to set_flash }
  end

  describe 'GET terms_of_service' do
    before(:each) do
      @app_config = FactoryGirl.create(:app_config)
      controller.instance_variable_set(:@app_configs, @app_config)
      get :terms_of_service
    end
    it { is_expected.to render_template('terms_of_service/index') }
    it 'assigns @app_config.terms_of_service to @tos' do
      expect(assigns(:tos)).to eq(@app_config.terms_of_service)
    end
  end

  describe 'PUT deactivate' do
    it 'should assign @objects_class2 to the object and controller '\
      'specified by params'
    it 'should delete @objects_class2'
    it 'should set the flash'
    it 'should redirect to request.referer'
  end

  describe 'PUT activate' do
    it 'should assign @model_to_activate to the model to be activated'
    it 'should call activatParents on the assigned model'
    it 'should revive @model_to_activate'
    it 'should set the flash'
    it 'should redirect to request.referer'
  end

  describe 'GET markdown_help' do
    before(:each) do
      get :markdown_help
    end
    it { is_expected.to render_template('shared/_markdown_help') }
    # TODO: not sure how to make sure that the js template is being rendered
    # as well.
  end
end
