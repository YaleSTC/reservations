module FeatureHelpers
  # make sure we have a working app
  def app_setup
    @app_config = FactoryGirl.create(:app_config)
    @category = FactoryGirl.create(:category)
    @eq_model =
      FactoryGirl.create(:equipment_model, category: @category)
    @eq_item = FactoryGirl.create(:equipment_item, equipment_model: @eq_model)
    @admin = FactoryGirl.create(:admin)
    @superuser = FactoryGirl.create(:superuser)
    @checkout_person = FactoryGirl.create(:checkout_person)
    @user = FactoryGirl.create(:user)
  end

  def empty_cart
    visit '/'
    click_link 'Empty Cart'
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

  def fill_in_login(user = @user)
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'passw0rd'
  end

  def update_cart_start_date(new_date_str)
    # fill in both visible / datepicker and hidden field
    fill_in 'cart_start_date_cart', with: new_date_str
    find(:xpath, "//input[@id='date_start_alt']").set new_date_str
    find('#cart_form').submit_form!
  end

  def update_cart_due_date(new_date_str)
    # fill in both visible / datepicker and hidden field
    fill_in 'cart_due_date_cart', with: new_date_str
    find(:xpath, "//input[@id='date_end_alt']").set new_date_str
    find('#cart_form').submit_form!
  end

  def add_item_to_cart(eq_model)
    # visit catalog to make sure our css selector works
    visit root_path
    within(:css, "#add_to_cart_#{eq_model.id}") do
      click_link 'Add to Cart'
    end
  end

  def change_reserver(reserver)
    fill_in 'Reserving For', with: reserver.id
    find('#cart_form').submit_form!
  end

  def sign_in_as_user(user)
    visit root_path
    click_link 'Sign In', match: :first
    fill_in_login(user)
    click_button 'Sign in'
    @current_user = user
  end

  def sign_out
    visit root_path
    click_link 'Log Out'
    @current_user = nil
  end

  def current_user
    visit root_path
    click_link 'My Profile'
    email = find('.page-header h1 small').text
    User.find_by_email(email)
  end

  def admin_routes
    RailsAdmin::Engine.routes.url_helpers
  end
end
