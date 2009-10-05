# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user
  helper_method :cart
  
  before_filter CASClient::Frameworks::Rails::Filter
  before_filter :first_time_user
  before_filter :cart

  def current_user
    @current_user ||= User.find_by_login(session[:cas_user])
  end
  
  def first_time_user
    if current_user.nil?
      flash[:notice] = "Hey there! Since this is your first time making a reservation, we'll
        need you to supply us with some basic contact information first."
      redirect_to new_user_path
    end
  end
  
  def cart
    session[:cart] ||= Cart.new
  end
  
  def update_cart
    session[:cart].set_start_date(Date.civil(params[:cart][:"start_date(1i)"].to_i,params[:cart][:"start_date(2i)"].to_i,params[:cart][:"start_date(3i)"].to_i))
    session[:cart].set_due_date(Date.civil(params[:cart][:"due_date(1i)"].to_i,params[:cart][:"due_date(2i)"].to_i,params[:cart][:"due_date(3i)"].to_i))
    flash[:notice] = "Cart dates updated."
    redirect_to root_path
  end
  
  def empty_cart
    session[:cart] = Cart.new
    flash[:notice] = "Cart emptied."
    redirect_to root_path
  end
  
  def logout
    @current_user = nil
    CASClient::Frameworks::Rails::Filter.logout(self)
  end
  
  def require_admin
    restricted_redirect_to(root_path) unless current_user.is_admin?
  end
  
  def require_user(user, new_path=root_path)
    restricted_redirect_to(new_path) unless current_user == user or current_user.is_admin?
  end
  
  def restricted_redirect_to(new_path=root_path)
    flash[:error] = "Sorry, that action is restricted."
    redirect_to new_path
  end
end
