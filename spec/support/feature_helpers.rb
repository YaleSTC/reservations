module FeatureHelpers
  # make sure we have a working app
  def app_setup
    @app_config = FactoryGirl.create(:app_config)
    @category = FactoryGirl.create(:category)
    @equipment_model_with_object =
      FactoryGirl.create(:equipment_model_with_object, category: @category)
    @admin = FactoryGirl.create(:admin)
    @user = FactoryGirl.create(:user)
  end

  def fill_in_registration
    fill_in 'Email',
            with: (0...8).map { (65 + rand(26)).chr }.join + '@example.com'
    fill_in 'user_password', with: 'passw0rd'
    fill_in 'user_password_confirmation', with: 'passw0rd'
    fill_in 'First name', with: 'John'
    fill_in 'Last name', with: 'Smith'
    fill_in 'Affiliation', with: 'Yale'
  end

  def fill_in_login
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'passw0rd'
  end
end
