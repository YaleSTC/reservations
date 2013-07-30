# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :layout
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter RubyCAS::Filter unless Rails.env.test?
  before_filter :app_setup_check
  before_filter :cart

  with_options :unless => lambda {|u| User.all.count == 0 } do |c|
    c.before_filter :load_configs
    c.before_filter :seen_app_configs
    c.before_filter :current_user
    c.before_filter :first_time_user
    c.before_filter :cart
    c.before_filter :fix_cart_date
    c.before_filter :set_view_mode
    c.before_filter :check_if_is_admin,  :only => [:activate, :deactivate]
  end

  helper_method :current_user
  helper_method :cart

  # -------- before_filter methods -------- #

  def app_setup_check
    if User.all.blank? || !AppConfig.first
      flash[:notice] = "Hey there! It looks like you haven't fully set up your application yet. To \
      create your first admin user and configure the application, please run $bundle exec rake app:setup \
      in the terminal. For more information, please see our github page: https://github.com/YaleSTC/reservations"
      render file: 'application_setup/index', layout: 'application'
    end
  end

  def load_configs
    @app_configs = AppConfig.first
  end

  def seen_app_configs
    if AppConfig.first.viewed == false
      flash[:notice] = "Since this is your first time viewing the application configurations, we recoomend\
      that you take some time to read each option and make sure that the settings are appropriate for your needs."
      redirect_to edit_app_configs_path
    end
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

  def set_view_mode
    if current_user && current_user.role == 'admin' && params[:view_mode]
      # gives a more user friendly notice when changing view modes
      messages_hash = { 'admin' => 'Admin',
                        'banned' => 'Banned User',
                        'checkout' => 'Checkout Person',
                        'normal' => 'Patron'}

      current_user.view_mode = params[:view_mode]
      current_user.save!
      flash[:notice] = "Viewing as #{messages_hash[current_user.view_mode]}."
      redirect_to(:back) and return
    end

  end

  def current_user
    # the commented out if statement is not necessary since User.find_by_login(nil) will return nil anyway
    @current_user ||= User.find_by_login(session[:cas_user]) # if session[:cas_user]
  end

  def check_if_is_admin
    unless current_user.role == 'admin'
      flash[:notice] = "Only administrators can do that!"
      redirect_to request.referer
    end
  end

  def fix_cart_date
    cart.set_start_date(Date.today) if cart.start_date < Date.today
  end

  #-------- end before_filter methods --------#

  def update_cart
    # set dates
    cart = session[:cart]
    flash.clear
    begin
      cart.set_start_date(Date.strptime(params[:cart][:start_date_cart],'%m/%d/%Y'))
      cart.set_due_date(Date.strptime(params[:cart][:due_date_cart],'%m/%d/%Y'))
      cart.set_reserver_id(params[:reserver_id])
    rescue ArgumentError => e
      cart.set_start_date(Date.today)
      flash[:error] = "Please enter a valid start or due date."
    end
    
    # validate
    errors = Reservation.validate_set(cart.reserver, cart.cart_reservations)
    # don't over-write flash if invalid date was set above
    flash[:error] ||= errors.to_sentence 

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

    session[:cart] = nil # do this instead?
    #create a new cart
    # session[:cart] = Cart.new
    # session[:cart].set_reserver_id(current_user.id)
    flash[:notice] = "Cart emptied."

    redirect_to root_path
  end

  def logout
    @current_user = nil
    RubyCAS::Filter.logout(self)
  end

  def require_admin(new_path=root_path)
    restricted_redirect_to(new_path) unless current_user.is_admin?(:as => 'admin')
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
    restricted_redirect_to(new_path) unless current_user == user or current_user.is_admin?(:as => 'admin')
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

  # activate and deactivate are overridden in the users controller because users are activated and deactivated differently
  def deactivate
    @objects_class2 = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (EM, EO, Category)
    @objects_class2.destroy #Deactivate the model you had originally intended to deactivate
    flash[:notice] = "Successfully deactivated " + params[:controller].singularize.titleize + ". Any related reservations or equipment have been deactivated as well."
    redirect_to request.referer  # Or use redirect_to(back).
  end

  def activate
    @model_to_activate = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (EM, EO, Category)
    activateParents(@model_to_activate)
    @model_to_activate.revive
    flash[:notice] = "Successfully reactivated " + params[:controller].singularize.titleize + ". Any related reservations or equipment have been reactivated as well."
    redirect_to request.referer # Or use redirect_to(back)
  end

  def markdown_help
    respond_to do |format|
      format.html{render :partial => 'shared/markdown_help'}
      format.js{render :template => 'shared/markdown_help_js'}
    end
  end

end
