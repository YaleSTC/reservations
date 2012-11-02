# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :layout
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter RubyCAS::Filter
  before_filter :app_setup, :if => lambda {|u| User.all.count == 0 }
  before_filter :current_user
  before_filter :load_configs
  before_filter :first_time_user
  before_filter :cart
  before_filter :set_view_mode

  helper_method :current_user
  helper_method :cart
  
  #-------- before_filter methods --------

  def app_setup
      redirect_to new_admin_user_path
  end
  
  def load_configs
    @app_configs = AppConfig.first
  end

  def first_time_user
    if current_user.nil? && params[:action] != "terms_of_service"
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
      flash[:notice] = "Viewing as Patron"
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

  def current_user
    @current_user ||= User.include_deleted.find_by_login(session[:cas_user]) if session[:cas_user]
  end

  #-------- end before_filter methods --------

  def update_cart
    # set dates
    flash.clear
    session[:cart].set_start_date(Date.strptime(params[:cart][:start_date_cart],'%m/%d/%Y'))
    session[:cart].set_due_date(Date.strptime(params[:cart][:due_date_cart],'%m/%d/%Y'))
    session[:cart].set_reserver_id(params[:reserver_id])
    
    # validate
    errors = Reservation.validate_set(cart.reserver, cart.cart_reservations)
    flash[:error] = errors.to_sentence

    # reload appropriate divs / exit
    respond_to do |format|
      format.js{render :template => "reservations/cart_dates_reload"}
        # guys i really don't like how this is rendering a template for js, but :action doesn't work at all
      format.html{render :partial => "reservations/cart_dates"}
    end
  end

  def empty_cart
    #destroy old cart reservations
    current_cart = session[:cart]
    CartReservation.where(:reserver_id => current_cart.reserver.id).destroy_all
    
    #create a new cart
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

  def terms_of_service
    @tos = @app_configs.terms_of_service
    render 'terms_of_service/index'
  end

  def deactivate
    if (current_user.is_admin)
      @objects_class2 = params[:controller].singularize.titleize.delete(' ').constantize.include_deleted.find(params[:id]) #Finds the current model (User, EM, EO, Category)
      if (params[:controller] != "users") #Search for children is not necessary if we are altering users.
        deactivateChildren(@objects_class2)
      end
      @objects_class2.destroy #Deactivate the model you had originally intended to deactivate
      flash[:notice] = "Successfully deactivated " + params[:controller].singularize.titleize + ". Any related reservations or equipment have been deactivated as well."
    else
      flash[:notice] = "Only administrators can do that!"
    end
    redirect_to request.referer   # Or use redirect_to(back).
 end

  def activate
    if (current_user.is_admin)
      @model_to_activate = params[:controller].singularize.titleize.delete(' ').constantize.include_deleted.find(params[:id]) #Finds the current model (User, EM, EO, Category)

      if (params[:controller] != "users") #Search for parents is not necessary if we are altering users.
        activateParents(@model_to_activate)
        @model_to_activate.revive
        activateChildren(@model_to_activate)
      else
        @model_to_activate.revive
      end

      flash[:notice] = "Successfully reactivated " + params[:controller].singularize.titleize + ". Any related reservations or equipment have been reactivated as well."
    else
      flash[:notice] = "Only administrators can do that!"
    end
    redirect_to request.referer  # Or use redirect_to(back)
  end
  
  def markdown_help
    respond_to do |format|
      format.html{render :partial => 'shared/markdown_help'}
      format.js{render :template => 'shared/markdown_help_js'}
    end
  end  

  def csv_import(filepath)
    # initialize
    imported_objects = []
    string = File.read(filepath)
    require 'csv'
    
    # import data by row
    CSV.parse(string, :headers => true) do |row|
      object_hash = row.to_hash.symbolize_keys
      
      # make all nil values blank
      object_hash.keys.each do |key|
        if object_hash[key].nil?
          object_hash[key] = ''
        end
      end
      imported_objects << object_hash
    end
    # return array of imported objects
    imported_objects
  end
end
