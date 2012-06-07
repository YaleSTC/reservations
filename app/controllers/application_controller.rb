# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user
  helper_method :cart
  
  before_filter RubyCAS::Filter
  before_filter :first_run
  before_filter :first_time_user
  before_filter :cart
  before_filter :set_view_mode

  def current_user
    @current_user ||= User.find_by_login(session[:cas_user])
  end
  
  #-------- before_filter methods --------
  def first_run
    Category.find_or_create_by_name("Accessories")
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

  def set_view_mode #(Analogous to department_chooser in shifts)
    if (params[:a_mode] && current_user.is_admin)
      current_user.update_attribute(:adminmode, 1)
	    current_user.update_attribute(:checkoutpersonmode, 0)
	    current_user.update_attribute(:normalusermode, 0)
	    current_user.update_attribute(:bannedmode, 0)
      flash[:notice] = "Viewing as Admin"
      redirect_to :action => "index" and return
    end
    if (params[:c_mode] && current_user.is_admin)
      current_user.update_attribute(:adminmode, 0)
	    current_user.update_attribute(:checkoutpersonmode, 1)
	    current_user.update_attribute(:normalusermode, 0)
	    current_user.update_attribute(:bannedmode, 0)
      flash[:notice] = "Viewing as Checkout Person"
      redirect_to :action => "index" and return
    end
    if (params[:n_mode] && current_user.is_admin)
	    current_user.update_attribute(:adminmode, 0)
	    current_user.update_attribute(:checkoutpersonmode, 0)
	    current_user.update_attribute(:normalusermode, 1)
	    current_user.update_attribute(:bannedmode, 0)
      flash[:notice] = "Viewing as Normal User"
      redirect_to :action => "index" and return
    end
    if (params[:b_mode] && current_user.is_admin)
	    current_user.update_attribute(:adminmode, 0)
      current_user.update_attribute(:checkoutpersonmode, 0)
	    current_user.update_attribute(:normalusermode, 0)
      current_user.update_attribute(:bannedmode, 1)
      flash[:notice] = "Viewing as Banned User"
      redirect_to :action => "index" and return
    end
  end
  #-------- end before_filter methods --------

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
    RubyCAS::Filter.logout(self)
  end
  
  def require_admin(new_path=root_path)
    restricted_redirect_to(new_path) unless current_user.is_admin_in_adminmode?
  end
  
  def require_checkout_person(new_path=root_path)
    restricted_redirect_to(new_path) unless current_user.can_checkout?
  end
  
  def require_login
    if current_user.nil?
      flash[:error] = "Sorry, that action requires you to log in."
      redirect_to root_path
    end
  end
  
  def require_user(user, new_path=root_path)
    restricted_redirect_to(new_path) unless current_user == user or current_user.is_admin_in_adminmode?
  end
  
  def require_user_or_checkout_person(user, new_path=root_path)
    restricted_redirect_to(new_path) unless current_user == user or current_user.can_checkout?
  end
  
  def restricted_redirect_to(new_path=root_path)
    flash[:error] = "Sorry, that action or page is restricted."
    redirect_to new_path
  end

  def deactivate
    params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]).destroy
    flash[:notice] = "Successfully deactivated " + params[:controller].singularize.titleize + "."
    redirect_to(:back)   # Or use redirect_to request.referer. <-This may pass more tests
  end

  def activate
    params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]).revive
    flash[:notice] = "Successfully reactivated " + params[:controller].singularize.titleize + "."
    redirect_to(:back)   # Or use redirect_to request.referer. <-This may pass more tests
  end

end
