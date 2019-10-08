# frozen_string_literal: true

# rubocop:disable ClassLength
class UsersController < ApplicationController
  load_and_authorize_resource
  layout 'application_with_sidebar', only: %i[show edit]

  autocomplete :user, :last_name, extra_data: %i[first_name username],
                                  display_value: :render_name

  skip_before_action :cart, only: %i[new create]
  skip_before_action :authenticate_user!, only: %i[new create]
  before_action :set_user,
                only: %i[show edit update destroy ban unban]
  before_action :check_cas_auth, only: %i[show new create quick_create
                                          edit update]

  include Autocomplete
  include Calendarable
  include CsvExport

  # ------------ before filter methods ------------ #

  def set_user
    @user = User.find(params[:id])
  end

  def check_cas_auth
    @cas_auth = ENV['CAS_AUTH']
  end

  # ------------ end before filter methods ------------ #

  def index
    @users = if params[:show_banned]
               User.order('username ASC')
             else
               User.active.order('username ASC')
             end

    respond_to do |format|
      format.html
      format.csv do
        col = %w[username first_name last_name nickname phone email affiliation]
        download_csv(User.all, col, "users_#{Time.zone.today}")
      end
    end
  end

  def show
    if @user.role == 'banned' && @user.id != current_user.id
      flash[:error] = 'Please note that this user is banned.'
    end
    @user_reservations = @user.reservations.includes(:equipment_item,
                                                     :equipment_model)
    @all_equipment = Reservation.active.for_reserver(@user)
    @show_equipment = { checked_out:  @user_reservations.checked_out,
                        overdue:      @user_reservations.overdue,
                        future:       @user_reservations.reserved,
                        past:         @user_reservations.returned,
                        past_overdue: @user_reservations.returned_overdue }
    unless AppConfig.check(:res_exp_time)
      @show_equipment[:missed] =
        @user_reservations.missed
    end
    @has_pending = @user_reservations.requested.count.positive?
  end

  def new # rubocop:disable all
    # if CAS authentication
    if @cas_auth
      # variable used in view
      @can_edit_username = current_user.present? && (can? :create, User)
      if current_user.nil? && session[:new_username]
        # This is a new user -> create an account for them
        @user = User.new(User.search(login: session[:new_username]))
        @user.username = session[:new_username] # default to current username
        flash[:notice] = 'Hey there! Since this is your first time making a '\
          'reservation, we\'ll need you to supply us with some basic '\
          'contact information.'
      elsif current_user.nil?
        # we don't have the current session's username
        # THIS ONLY APPLIES TO CAS
        flash[:error] = 'Something seems to have gone wrong. Please try '\
          'that again.'
        redirect_to root_path
      else
        @user = User.new
      end
    # if database authenticatable
    else
      @can_edit_username = true
      @user = User.new
      if current_user
        @user = User.new
      else
        flash[:notice] = 'Hey there! Since this is your first time making a '\
          'reservation, we\'ll need you to supply us with some basic '\
          'contact information.'
      end
    end
  end

  def create # rubocop:disable all
    @user = User.new(user_params.to_h)
    @user.role = 'normal' if user_params[:role].blank?
    @user.view_mode = @user.role
    # if we're using CAS
    if @cas_auth
      # pull from our CAS hackery if you're not an admin/superuser creating a
      # new user
      if current_user && can?(:manage, Reservation)
        @user.cas_login = user_params[:username]
      else
        @user.cas_login = session[:new_username]
        @user.username = @user.cas_login
      end
    else
      # if not using CAS, just put the e-mail as the username
      @user.username = @user.email
    end
    if @user.save
      # delete extra session parameter if we came from CAS hackery
      session.delete(:new_username) if @cas_auth
      flash[:notice] = 'Successfully created user.'
      # log in the new user
      bypass_sign_in @user unless current_user
      redirect_to user_path(@user)
    else
      # variable used in view
      @can_edit_username = current_user.present? && (can? :create, User)
      render :new
    end
  end

  def quick_new
    ldap_result = User.search(login: params[:possible_login])
    @user = User.new(ldap_result)

    # Does netID exist?
    if ldap_result.nil?
      @message = 'Sorry, the login that you entered does not exist.
      You cannot create a user profile without a valid login.'
    # Is there a user record already?
    elsif User.find_by(username: params[:possible_login])
      @message = 'You cannot create a new user, as the login you entered is '\
      'already associated with a user. If you would like to reserve for '\
      'them, please select their name from the drop-down options in the cart.'
    end
    respond_to :html, :js
  end

  def quick_create
    @user = User.new(user_params.to_h)
    @user.role = 'normal' if user_params[:role].blank?
    @user.view_mode = @user.role
    # if we're using CAS, set the cas_login correctly
    @user.cas_login = user_params[:username] if @cas_auth

    if @user.save
      cart.reserver_id = @user.id
      flash[:notice] = 'Successfully created user.'
      render action: 'create_success'
    else
      render action: 'load_form_errors'
    end
  end

  def edit
    # refer to the page as Profile if current user, and as User elsewise
    @edit_title_text = current_user == @user ? 'Profile' : 'User'
    @can_edit_username = can? :edit_username, User
  end

  def update # rubocop:disable CyclomaticComplexity, PerceivedComplexity
    @edit_title_text = current_user == @user ? 'Profile' : 'User'
    par = user_params
    # use :update_with_password when we're not using CAS and you're editing
    # your own profile
    if @cas_auth || ((can? :manage, User) && (@user.id != current_user.id))
      method = :update
      # delete the current_password key from the params hash just in case it's
      # present (and :update will throw an error)
      par.delete('current_password')
    else
      method = :update_with_password
      # make sure we update the username as well
      par[:username] = par[:email]
    end
    if @user.send(method, par)
      # sign in the user if you've edited yourself since you have a new
      # password, otherwise don't
      bypass_sign_in @user if @user.id == current_user.id
      flash[:notice] = 'Successfully updated user.'
      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def ban
    if @user.role == 'guest'
      flash[:error] = 'Cannot ban guest.'
      redirect_to(request.referer) && return
    end
    if @user == current_user
      flash[:error] = 'You cannot ban yourself.'
      redirect_to(request.referer) && return
    end
    @user.update(role: 'banned', view_mode: 'banned')
    flash[:notice] = "#{@user.name} was banned succesfully."
    redirect_to request.referer
  end

  def unban
    if @user.role == 'guest'
      flash[:error] = 'Cannot unban guest.'
      redirect_to(request.referer) && return
    end
    @user.update(role: 'normal', view_mode: 'normal')
    flash[:notice] = "#{@user.name} was restored to patron status."
    redirect_to request.referer
  end

  def find # rubocop:disable CyclomaticComplexity, PerceivedComplexity
    if params[:fake_searched_id].blank?
      flash[:alert] = 'Search field cannot be blank'
      redirect_back(fallback_location: root_path) && return
    elsif params[:searched_id].blank?
      # this code is a hack to allow hitting enter in the search box to go
      # direclty to the first user and still user the
      # rails3-jquery-autocomplete gem for the search box. Unfortunately the
      # feature isn't built into the gem.
      users = get_autocomplete_items(term: params[:fake_searched_id])
      if users.present?
        @user = users.first
        redirect_to(manage_reservations_for_user_path(@user.id)) && return
      else
        flash[:alert] = 'Please select a valid user'
        redirect_back(fallback_location: root_path) && return
      end
    else
      @user = User.find(params[:searched_id])
      redirect_to(manage_reservations_for_user_path(@user.id)) && return
    end
  end

  private

  def user_params
    permitted_attributes = %i[first_name last_name nickname phone
                              email affiliation terms_of_service_accepted
                              created_by_admin]
    unless @cas_auth
      permitted_attributes += %i[password password_confirmation
                                 current_password]
    end
    permitted_attributes << :username if can? :manage, Reservation
    if can? :assign, :requirements
      permitted_attributes += [:user_ids, :role, requirement_ids: []]
    end
    p = params.require(:user).permit(*permitted_attributes)
    p[:view_mode] = p[:role] if p[:role]
    p
  end

  def generate_calendar_reservations
    # we need uniq because it otherwise includes overdue reservations in the
    # date range twice
    (@user.reservations.includes(:equipment_item)
      .overlaps_with_date_range(@start_date, @end_date).finalized
      .where.not(status: 'archived') + \
      @user.reservations.includes(:equipment_item).overdue).uniq
  end

  def generate_calendar_resource
    @user
  end

  def calendar_name_method
    :equipment_model
  end
end
