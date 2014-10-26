module FeatureHelpers
  def app_setup
    @app_config = FactoryGirl.create(:app_config)
    @equipment_model_with_object = FactoryGirl.create(:equipment_model_with_object)
    @admin = FactoryGirl.create(:admin)
    @user = FactoryGirl.create(:user)
  end
end