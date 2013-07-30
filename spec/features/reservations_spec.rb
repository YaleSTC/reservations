require 'spec_helper'

feature "Reservations" do
	background do
		user = FactoryGirl.create(:user)
		ApplicationController.set_cas_user(user.login)
		# @user = FactoryGirl.create(:user)
		# session[:cart] = Cart.new
  #       session[:cart].reserver_id = @user.id
	end
	scenario " redirect to root path" do
		visit(root_path)
	end
	# scenario "reserve dates" do
	# 	select Date.today+3, from: 'Start Date'
	# 	select Date.today+10, from: 'Due Date'
	# end
	# scenario "add item to cart" do
	# 	click_button 'Add to Cart'
	# end
	# scenario "Make new reservation" do
	# 	click_button 'Make Reservation'
	# end
end

