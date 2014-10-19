# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :layout
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :app_setup_check
  before_filter :authenticate_user!, unless: :devise_controller?
  skip_before_filter :authenticate_user!, only: [:update_cart, :empty_cart, :terms_of_service]
  before_filter :cart, unless: :devise_controller?

  with_options unless: lambda { |u| User.count == 0 } do |c|
    c.before_filter :load_configs
    c.before_filter :seen_app_configs
    # c.before_filter :first_time_user
    c.before_filter :fix_cart_date
    c.before_filter :set_view_mode
    c.before_filter :check_view_mode
    c.before_filter :make_cart_compatible
  end

  helper_method :cart

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Sorry, that action or page is restricted."
    if current_user && current_user.view_mode == 'banned'
      flash[:error] = "That action is restricted; it looks like you're a banned user! Talk to your administrator, maybe they'll be willing to lift your restriction."
    end
    #redirect_to request.referer ? request.referer : main_app.root_url
    redirect_to main_app.root_url
  end

  # -------- before_filter methods -------- #

  def app_setup_check
    unless AppConfig.first && (User.count != 0)
      flash[:notice] = "Hey there! It looks like you haven't fully set up your application yet. To \
      create your first superuser and configure the application, please run $bundle exec rake app:setup \
      in the terminal. For more information, please see our github page: https://github.com/YaleSTC/reservations"
      render file: 'application_setup/index', layout: 'application'
    end
  end

  def load_configs
    @app_configs = AppConfig.first
  end

  def seen_app_configs
    return if AppConfig.first.viewed || current_user.nil?
    if can? :edit, :app_config
      flash[:notice] = "Since this is your first time viewing the application configurations, we recommend\
      that you take some time to read each option and make sure that the settings are appropriate for your needs."
      redirect_to edit_app_configs_path
    else
      flash[:notice] = "It looks like this application has not yet been fully set up. Check back in a little while or contact your system administrator"
      render file: 'application_setup/index', layout: 'application'
    end
  end

  # def first_time_user
  #   if current_user.nil? && params[:action] != "terms_of_service"
  #     flash[:notice] = "Hey there! Since this is your first time making a reservation, we'll
  #       need you to supply us with some basic contact information."
  #     redirect_to new_user_path
  #   end
  # end

  def cart
    # ensure that we call current_or_guest_user during a new request to delete
    # the guest user from the db
    reserver = current_or_guest_user
    session[:cart] ||= Cart.new
    # if there is no cart reserver_id or the old cart reserver was deleted
    # (i.e. we've logged in and the guest user was destroyed)
    if session[:cart].reserver_id.nil? || User.find_by_id(session[:cart].reserver_id).nil?
      session[:cart].reserver_id = reserver.id
    end
    session[:cart]
  end

  def set_view_mode
    if (can? :change, :views) && params[:view_mode]
      # gives a more user friendly notice when changing view modes
      messages_hash = { 'admin' => 'Admin',
                        'banned' => 'Banned User',
                        'checkout' => 'Checkout Person',
                        'superuser' => 'Superuser',
                        'normal' => 'Patron'}
      if (params[:view_mode] == 'superuser')
        authorize! :view_as, :superuser
      end
      current_user.view_mode = params[:view_mode]
      current_user.save!
      flash[:notice] = "Viewing as #{messages_hash[current_user.view_mode]}."
      redirect_to(:back) and return
    end

  end

  def check_active_admin_permission
    if cannot? :access, :active_admin
      raise CanCan::AccessDenied.new()
    end
  end

  def check_view_mode
    return unless current_user
    if (can? :change, :views) && (current_user.view_mode != current_user.role)
      flash[:persistent] = "Currently viewing as #{current_user.view_mode} user. You can switch back to your regular view \
                  #{ActionController::Base.helpers.link_to('below','#view_as')} \
                  (see #{ActionController::Base.helpers.link_to('here','https://yalestc.github.io/reservations/')} for details)."
    end
  end

  def fix_cart_date
    cart.start_date = (Date.current) if cart.start_date < Date.current
    cart.fix_due_date
  end

  # If user's session has an old Cart object that stores items in Array rather
  # than a Hash (see #587), regenerate the Cart.
  # TODO: Remove in ~2015, when nobody could conceivably run the old app?
  def make_cart_compatible
    unless session[:cart].items.is_a? Hash
      session[:cart] = Cart.new
    end
  end

  #-------- end before_filter methods --------#

  def update_cart
    cart = session[:cart]
    flash.clear
    begin
      cart.start_date = params[:cart][:start_date_cart].to_date
      cart.due_date = params[:cart][:due_date_cart].to_date
      cart.fix_due_date
      cart.reserver_id = params[:reserver_id].blank? ? current_or_guest_user.id : params[:reserver_id]
    rescue ArgumentError
      cart.start_date = Date.current
      flash[:error] = "Please enter a valid start or due date."
    end

    # get soft blackout notices
    notices = []
    notices << Blackout.get_notices_for_date(cart.start_date,:soft)
    notices << Blackout.get_notices_for_date(cart.due_date,:soft)
    notices = notices.reject{ |a| a.blank? }.to_sentence
    notices += "\n" unless notices.blank?

    # validate
    errors = cart.validate_all
    # don't over-write flash if invalid date was set above
    flash[:error] ||= notices + errors.to_sentence
    flash[:notice] = "Cart updated."

    # reload appropriate divs / exit
    if params[:controller] == 'catalog'
      prepare_catalog_index_vars
    end

    respond_to do |format|
      format.js{render template: "cart_js/cart_dates_reload"}
        # guys i really don't like how this is rendering a template for js, but :action doesn't work at all
      format.html{render partial: "reservations/cart_dates"}
    end
  end

  # if user is logged in, return current_user, else return guest_user
  # https://github.com/plataformatec/devise/wiki/How-To:-Create-a-guest-user
  def current_or_guest_user
    if current_user
      if session[:guest_user_id]
        logging_in
        session[:guest_user_id] = nil
      end
      current_user
    else
      guest_user
    end
  end

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user
    # Cache the value the first time it's gotten.
    @cached_guest_user ||= User.find(session[:guest_user_id] ||= find_guest_user.id)

  rescue ActiveRecord::RecordNotFound # if session[:guest_user_id] invalid
     session[:guest_user_id] = nil
     guest_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_or_guest_user)
  end


  def prepare_catalog_index_vars(eq_models = nil)
    # prepare the catalog
    eq_models ||= EquipmentModel.active.
                              order('categories.sort_order ASC, equipment_models.name ASC').
                              includes(:category, :requirements).
                              page(params[:page]).
                              per(session[:items_per_page])
    @eq_models_by_category = eq_models.to_a.group_by(&:category)

    @available_string = "available from #{cart.start_date.strftime("%b %d, %Y")} to #{cart.due_date.strftime("%b %d, %Y")}"

    # create an hash of em id's as keys and their availability as the value
    @availability_hash = Hash.new

    # first get an array of all the paginated ids
    id_array = []
    eq_models.each do |em|
      id_array << em.id
    end

    # 1 query to grab all the active related equipment objects
    eq_objects = EquipmentObject.active.where(equipment_model_id: id_array).all

    # 1 query to grab all the related reservations
    source_reservations = Reservation.not_returned.where(equipment_model_id: id_array).all

    # build the hash using class methods that use 0 queries
    eq_models.each do |em|
      @availability_hash[em.id] = [EquipmentObject.for_eq_model(em.id,eq_objects) - \
        Reservation.number_overdue_for_eq_model(em.id,source_reservations) - \
        em.num_reserved(cart.start_date,cart.due_date,source_reservations), 0].max
    end
    @page_eq_models_by_category = eq_models


  end

  def empty_cart
    session[:cart].purge_all if session[:cart]
    flash[:notice] = "Cart emptied."
    respond_to do |format|
      format.js{render template: "cart_js/reload_all"}
      format.html{redirect_to root_path}
    end
  end

  def require_login
    if current_user.nil?
      flash[:error] = "Sorry, that action requires you to log in."
      redirect_to root_path
    end
  end

  def terms_of_service
    @tos = @app_configs.terms_of_service
    render 'terms_of_service/index'
  end

  # activate and deactivate are overridden in the users controller because users are activated and deactivated differently
  def deactivate
    authorize! :be, :admin
    @objects_class2 = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (EM, EO, Category)
    @objects_class2.destroy #Deactivate the model you had originally intended to deactivate
    flash[:notice] = "Successfully deactivated " + params[:controller].singularize.titleize + ". Any related equipment has been deactivated as well."
    redirect_to request.referer  # Or use redirect_to(back).
  end

  def activate
    authorize! :be, :admin
    @model_to_activate = params[:controller].singularize.titleize.delete(' ').constantize.find(params[:id]) #Finds the current model (EM, EO, Category)
    activate_parents(@model_to_activate)
    @model_to_activate.revive
    flash[:notice] = "Successfully reactivated " + params[:controller].singularize.titleize + ". Any related equipment has been reactivated as well."
    redirect_to request.referer # Or use redirect_to(back)
  end

  def markdown_help
    respond_to do |format|
      format.html{render partial: 'shared/markdown_help'}
      format.js{render template: 'shared/markdown_help_js'}
    end
  end

  # Checks if params[:terms_of_service_accepted] is necessary; if filled-out,
  # saves the state of the user; if not filled out and necessary, returns false.
  # Otherwise, returns true.
  def check_tos(user)
    return true if user.terms_of_service_accepted

    user.terms_of_service_accepted = params[:terms_of_service_accepted].present?
    return user.terms_of_service_accepted ? user.save : (flash[:error] = "You must confirm that the user accepts the Terms of Service.") && false
  end

  private

  # modify redirect after signing in
  def after_sign_in_path_for(user)
    # CODE FOR CAS LOGIN --> NEW USER
    if current_user && current_user.id.nil? && current_user.username
      session[:new_username] = current_user.username
      new_user_path
    else
      super
    end
  end

  # https://github.com/plataformatec/devise/wiki/How-To:-Create-a-guest-user
  # called (once) when the user logs in
  def logging_in
    # any code we need to run to transfer the cart over goes here
    # our current cart method will reset the reserver to current_user if the
    # old reserver (i.e. the guest user) was deleted, so we don't need to
    # explicitly switch the reserver_id
  end

  # find guest user - looks for existing guest user in the database and
  # creates a new one if one doesn't exist. This should only be called once
  # PER INSTANCE, and means that we won't clog up our Users table w/ guest
  # records.
  def find_guest_user
    guest = User.find_by_role('guest')
    if guest
      session[:guest_user_id] = guest.id
      guest
    else
      create_guest_user
    end
  end

  def create_guest_user
    username = generate_guest_username
    # ensure no matches since we index
    while User.find_by_username(username)
      username = generate_guest_username
    end
    u = User.create(
      username: username,
      first_name: 'Guest',
      last_name: 'User',
      role: 'guest')
    u.save!(:validate => false)
    session[:guest_user_id] = u.id
    u
  end

  def generate_guest_username
    "guest#{rand(100)}"
  end

end
