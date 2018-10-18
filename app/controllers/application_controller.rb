# frozen_string_literal: true

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# rubocop:disable ClassLength
class ApplicationController < ActionController::Base
  helper :layout

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery with: :exception
  before_action :app_setup_check
  before_action :authenticate_user!, unless: :skip_authentication?

  with_options unless: ->(_u) { User.count.zero? } do |c|
    c.before_action :load_configs
    c.before_action :seen_app_configs
    c.before_action :fix_cart_date
    c.before_action :set_view_mode
    c.before_action :check_view_mode
  end

  before_action :cart, unless: :devise_controller?

  helper_method :cart, :current_or_guest_user

  rescue_from CanCan::AccessDenied do |_exception|
    flash[:error] = 'Sorry, that action or page is restricted.'
    if current_user && current_user.view_mode == 'banned'
      flash[:error] = 'That action is restricted; it looks like you\'re a '\
        'banned user! Talk to your administrator, maybe they\'ll be willing '\
        'to lift your restriction.'
    end
    # redirect_to request.referer ? request.referer : main_app.root_url
    redirect_to main_app.root_url
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    flash[:error] = 'Oops, you tried to go somewhere that doesn\'t exist.'
    redirect_to main_app.root_url
  end

  # this is for security; handles when an invalid controller class is passed
  # in params[:controller] or params[:class]
  rescue_from KeyError do |_exception|
    flash[:error] = 'Oops, you tried to go somewhere that doesn\'t exist.'
    redirect_to main_app.root_url
  end

  # -------- before_action methods -------- #

  def app_setup_check
    return if AppConfig.first && (User.count != 0)
    flash[:notice] = 'Hey there! It looks like you haven\'t fully set up '\
      'your application yet. To create your first superuser and configure '\
      'the application, please run $bundle exec rake app:setup in the '\
      'terminal. For more information, please see our github page: '\
      'https://github.com/YaleSTC/reservations'
    render file: 'application_setup/index', layout: 'application'
  end

  def load_configs
    @app_configs = AppConfig.first
  end

  def seen_app_configs
    return if AppConfig.check(:viewed) || current_user.nil?
    if can? :edit, :app_config
      flash[:notice] = 'Since this is your first time viewing the '\
        'application configurations, we recommend that you take some time '\
        'to read each option and make sure that the settings are '\
        'appropriate for your needs.'
      redirect_to edit_app_configs_path
    else
      flash[:notice] = 'It looks like this application has not yet been '\
        'fully set up. Check back in a little while or contact your system '\
        'administrator.'
      render file: 'application_setup/index', layout: 'application'
    end
  end

  def cart
    # make sure we reset the reserver when we log in
    reserver = current_user ? current_user : current_or_guest_user
    session[:cart] ||= Cart.new
    make_cart_compatible
    # if there is no cart reserver_id or the old cart reserver was deleted
    # (i.e. we've logged in and the guest user was destroyed)
    if session[:cart].reserver_id.nil? ||
       User.find_by(id: session[:cart].reserver_id).nil?
      session[:cart].reserver_id = reserver.id
    end
    session[:cart].fix_items
    session[:cart]
  end

  def set_view_mode
    return unless (can? :change, :views) && params[:view_mode]
    # gives a more user friendly notice when changing view modes
    messages_hash = { 'admin' => 'Admin',
                      'banned' => 'Banned User',
                      'checkout' => 'Checkout Person',
                      'superuser' => 'Superuser',
                      'normal' => 'Patron',
                      'guest' => 'Guest' }
    authorize! :view_as, :superuser if params[:view_mode] == 'superuser'
    current_user.view_mode = params[:view_mode]
    current_user.save!(validate: false)
    flash[:notice] = "Viewing as #{messages_hash[current_user.view_mode]}."
    redirect_back(fallback_location: root_path) && return
  end

  def check_active_admin_permission
    return if can? :access, :active_admin
    raise CanCan::AccessDenied.new, 'Access Denied.'
  end

  def check_view_mode
    return unless current_user
    return unless (can? :change, :views) &&
                  (current_user.view_mode != current_user.role)
    doc_link = '[here](https://yalestc.github.io/reservations/)'
    below_link = '[below](#view_as)'
    msg = "Currently viewing as #{current_user.view_mode} "\
      " user. You can switch back to your regular view #{below_link} (see "\
      "#{doc_link} for details)."
    flash[:persistent] = msg
  end

  def fix_cart_date
    cart.start_date = Time.zone.today if cart.start_date < Time.zone.today
    cart.fix_due_date
  end

  # If user's session has an old Cart object that stores items in Array rather
  # than a Hash (see #587), regenerate the Cart.
  # TODO: Remove in ~2015, when nobody could conceivably run the old app?
  def make_cart_compatible
    return if session[:cart].items.is_a? Hash
    session[:cart] = Cart.new
  end

  # check to see if the guest user functionality is disabled
  def guests_disabled?
    !AppConfig.check(:enable_guests)
  end

  # check to see if we should skip authentication; either looks to see if the
  # Devise controller is running or if we're utilizing one of the guest-
  # accessible routes with guests disabled
  def skip_authentication?
    devise_controller? ||
      (%w[update_cart empty_cart terms_of_service]
      .include?(params[:action]) && !guests_disabled?)
  end

  #-------- end before_action methods --------#

  def update_cart # rubocop:disable MethodLength, AbcSize
    cart = session[:cart]
    flash.clear
    begin
      cart.start_date = params[:cart][:start_date_cart].to_date
      cart.due_date = params[:cart][:due_date_cart].to_date
      cart.fix_due_date
      cart.reserver_id =
        if params[:reserver_id].blank?
          cart.reserver_id = current_or_guest_user.id
        else
          params[:reserver_id]
        end
    rescue ArgumentError
      cart.start_date = Time.zone.today
      flash[:error] = 'Please enter a valid start or due date.'
    end

    # get soft blackout notices
    notices = []
    notices << Blackout.get_notices_for_date(cart.start_date, :soft)
    notices << Blackout.get_notices_for_date(cart.due_date, :soft)
    notices = notices.reject(&:blank?).to_sentence
    notices += "\n" if notices.present?

    # validate
    @errors = cart.validate_all
    # don't over-write flash if invalid date was set above
    flash[:error] ||= notices + "\n" + @errors.join("\n")
    flash[:notice] = 'Cart updated.'

    # reload appropriate divs / exit
    prepare_catalog_index_vars if params[:controller] == 'catalog'
  end

  # runs update cart and then reloads the javascript for the dates in sidebar
  def reload_catalog_cart
    update_cart
    respond_to do |format|
      format.js { render template: 'cart_js/cart_dates_reload' }
      # guys i really don't like how this is rendering a template for js,
      # but :action doesn't work at all
      format.html { render partial: 'reservations/cart_dates' }
    end
  end

  # if user is logged in, return current_user, else return guest_user
  # https://github.com/plataformatec/devise/wiki/How-To:-Create-a-guest-user
  def current_or_guest_user
    current_user ? current_user : guest_user
  end

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user
    @cached_guest ||= create_guest_user
  end

  # allow CanCanCan to use the guest user when we're not logged in
  def current_ability
    @current_ability ||= Ability.new(current_or_guest_user)
  end

  # rubocop:disable MethodLength, AbcSize
  def prepare_catalog_index_vars(eq_models = nil)
    # prepare the catalog
    eq_models ||=
      EquipmentModel.active
                    .order('categories.sort_order ASC, '\
                           'equipment_models.name ASC')
                    .includes(:category, :requirements)
                    .page(params[:page])
                    .per(session[:items_per_page])
    @eq_models_by_category = eq_models.to_a.group_by(&:category)

    @available_string = 'available from '\
      "#{cart.start_date.strftime('%b %d, %Y')} to "\
      "#{cart.due_date.strftime('%b %d, %Y')}"

    # create an hash of em id's as keys and their availability as the value
    @availability_hash = {}
    # create a hash of em id's as keys and their qualifications as the value
    @qualifications_hash = {}

    # first get an array of all the paginated ids
    id_array = []
    eq_models.each do |em|
      id_array << em.id
    end

    # 1 query to grab all the active related equipment items
    eq_items = EquipmentItem.active.where(equipment_model_id: id_array).all

    # 1 query to grab all the related reservations
    source_reservations =
      Reservation.active.where(equipment_model_id: id_array).all

    # for getting qualifications associated between the model and the reserver
    reserver = cart.reserver_id ? User.find(cart.reserver_id) : nil

    eq_models.each do |em|
      # build the hash using class methods that use 0 queries
      @availability_hash[em.id] =
        [EquipmentItem.for_eq_model(em.id, eq_items)\
        - em.num_busy(cart.start_date, cart.due_date, source_reservations)\
        - cart.items[em.id].to_i, 0].max

      # have requirements as part of equipment model itself
      restricted = em.model_restricted?(cart.reserver_id)
      next unless restricted
      @qualifications_hash[em.id] =
        helpers.list_requirement_admins(reserver, em)
    end

    @page_eq_models_by_category = eq_models
  end
  # rubocop:enable MethodLength, AbcSize

  def empty_cart
    session[:cart]&.purge_all
    flash[:notice] = 'Cart emptied.'
    respond_to do |format|
      format.js do
        prepare_catalog_index_vars
        render template: 'cart_js/reload_all'
      end
      format.html { redirect_to root_path }
    end
  end

  def terms_of_service
    @tos = @app_configs.terms_of_service
    render 'terms_of_service/index'
  end

  # activate and deactivate are overridden in the users controller because
  # users are activated and deactivated differently
  def deactivate
    authorize! :deactivate, :items
    # Finds the current model (EM, EI, Category)
    @items_class2 = ClassFromString.equipment!(params[:controller])
                                   .find(params[:id])
    # Deactivate the model you had originally intended to deactivate
    @items_class2.destroy
    flash[:notice] = 'Successfully deactivated '\
                   + params[:controller].singularize.titleize\
                   + '. Any related equipment has been deactivated as well.'
    redirect_to request.referer # Or use redirect_to(back).
  end

  def activate
    authorize! :activate, :items
    # Finds the current model (EM, EI, Category)
    @model_to_activate = ClassFromString.equipment!(params[:controller])
                                        .find(params[:id])
    activate_parents(@model_to_activate)
    @model_to_activate.revive
    flash[:notice] = 'Successfully reactivated '\
                   + params[:controller].singularize.titleize\
                   + '. Any related equipment has been reactivated as well.'
    redirect_to request.referer # Or use redirect_to(back)
  end

  def markdown_help
    respond_to do |format|
      format.html { render partial: 'shared/markdown_help' }
      format.js { render template: 'shared/markdown_help_js' }
    end
  end

  private

  # modify redirect after signing in
  def after_sign_in_path_for(user)
    # CODE FOR CAS LOGIN --> NEW USER
    if ENV['CAS_AUTH'] && current_user && current_user.id.nil? &&
       current_user.username
      # store username in session since there's a request in between
      session[:new_username] = current_user.username
      new_user_path
    else
      super
    end
  end

  def create_guest_user
    User.new(
      username: 'guest',
      first_name: 'Guest',
      last_name: 'User',
      role: 'guest',
      view_mode: 'guest'
    )
  end
end
