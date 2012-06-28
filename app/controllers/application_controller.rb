# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter RubyCAS::Filter
  before_filter :first_time_user
  before_filter :cart
  before_filter :set_view_mode
  before_filter :current_user
  before_filter :make_app_config
  #before_filter :bind_pry_before_everything

  helper_method :current_user
  helper_method :cart

  def bind_pry_before_everything
    binding.pry
  end

  def current_user
    @current_user ||= User.find_by_login(session[:cas_user]) if session[:cas_user]
  end

  #-------- before_filter methods --------
  
  def make_app_config
    if @app_config.nil?
      AppConfig.create!({ :site_title => "Reservations",
                        :admin_email => "admin@admin.admin",
                       :department_name => "School of Art Digital Technology Office",
                       :contact_link_text => "Contact Us", 
                       :contact_link_location => "mailto:contact.us@change.com", 
                       :home_link_text => "Home", 
                       :home_link_location => "http://clc.yale.edu", 
                       :default_per_cat_page => 20,
                       :upcoming_checkin_email_body => "Dear @user@,
                       Please remember to return the equipment you borrowed from us:

                       @equipment_list@

                       If the equipment is returned after 4 pm on @return_date@ you will be charged a late fee or replacement fee. Repeated late returns will result in the privilege to make further reservations for the rest of the term to be revoked.

                       Thank you,
                       @department_name@",
                       :overdue_checkout_email_body => "Dear @user@,
                       You have missed a scheduled equipment checkout, so your equipment may be released and checked out to other students.

                       Thank you,
                       @department_name@",
                       :overdue_checkin_email_body => "Dear @user@,
                       You were supposed to return the equipment you borrowed from us on @return_date@ but because you have failed to do so, you will be charged @late_fee@ / day until the equipment is returned. Failure to return equipment will result in replacement fees and revocation of borrowing privileges.

                       Thank you,
                       @department_name@"
                       })
    end
  end
  
  
  
  def first_time_user
    if current_user.nil?
      flash[:notice] = "Hey there! Since this is your first time making a reservation, we'll
        need you to supply us with some basic contact information."
      redirect_to new_user_path
    end
  end

  def cart
    session[:cart] ||= Cart.new
    if session[:cart].reserver_id.nil?
      session[:cart].set_reserver_id(current_user.id) if current_user
    end
    session[:cart]
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
    session[:cart].set_start_date(Date.strptime(params[:start_date_cart],'%m/%d/%Y'))
    session[:cart].set_due_date(Date.strptime(params[:due_date_cart],'%m/%d/%Y'))
#    session[:cart].set_start_date(Date.strptime(params[:cart][:start_date_cart],'%m/%d/%Y'))
#    session[:cart].set_due_date(Date.strptime(params[:cart][:due_date_cart],'%m/%d/%Y'))
    session[:cart].set_reserver_id(params[:reserver_id])
    flash[:notice] = "Cart dates updated."
    if !cart.valid_dates?
      flash[:error] = cart.errors.values.flatten.join("<br/>").html_safe
      cart.errors.clear
    end
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render :template => "reservations/cart_dates_js"}
    end
  end

  def empty_cart
    session[:cart] = Cart.new
    session[:cart].set_reserver_id(current_user.id)
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
    if (current_user.is_admin)
      @objects_class2 = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (User, EM, EO, Category)
      if (params[:controller] != "users") #Search for children is not necessary if we are altering users.
        deactivateChildren(@objects_class2)
      end
      @objects_class2.destroy #Deactivate the model you had originally intended to deactivate
      flash[:notice] = "Successfully deactivated " + params[:controller].singularize.titleize + ". Any child objects have been deactivated as well."
    else
      flash[:notice] = "Only administrators can do that!"
    end
    redirect_to request.referer   # Or use redirect_to(back).
 end

  def activate
    if (current_user.is_admin)
      @model_to_activate = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (User, EM, EO, Category)
      if (params[:controller] != "users") #Search for parents is not necessary if we are altering users.
        activateParents(@model_to_activate)
      end
      @model_to_activate.revive #Activate the model you had originally intended to activate
      flash[:notice] = "Successfully reactivated " + params[:controller].singularize.titleize + ". Any parent objects have been reactivated as well."
    else
      flash[:notice] = "Only administrators can do that!"
    end
    redirect_to request.referer  # Or use redirect_to(back)
  end

end
