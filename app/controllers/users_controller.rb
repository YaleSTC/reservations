class UsersController < ApplicationController
  load_and_authorize_resource
  layout 'application_with_sidebar', only: [:show, :edit]

  autocomplete :user, :last_name, extra_data: [:first_name, :login], display_value: :render_name

  skip_filter :cart, only: [:new, :create]
  skip_filter :first_time_user, only: [:new, :create]
  before_filter :set_user, only: [:show, :edit, :update, :destroy, :ban, :unban]

  include ActivationHelper
  include Autocomplete

  # ------------ before filter methods ------------ #

  def set_user
    @user = User.find(params[:id])
  end

  # ------------ end before filter methods ------------ #


  def index
    if params[:show_banned]
      @users = User.order('login ASC')
    else
      @users = User.active.order('login ASC')
    end
  end

  def show
    @user_reservations = @user.reservations
    @all_equipment = Reservation.active.for_reserver(@user)
    @show_equipment = { checked_out:  @user.reservations.
                                            select {|r| \
                                              (r.status == "checked out") || \
                                              (r.status == "overdue")},
                        overdue:      @user.reservations.overdue,
                        future:       @user.reservations.reserved,
                        past:         @user.reservations.returned,
                        missed:       @user.reservations.missed,
                        past_overdue: @user.reservations.returned.
                                            select {|r| \
                                              r.status == "returned overdue"} }
  end

  def new
    @can_edit_login = current_user.present? && (can? :create, User) # used in view

    if current_user.nil?
      # This is a new user -> create an account for them
      @user = User.new(User.search_ldap(session[:cas_user]))
      @user.login = session[:cas_user] #default to current login

      # TODO: What should it render?
      @partial_to_render = 'form'
    else
      # Someone with permissions is creating a new user
      ldap_result = User.search_ldap(params[:possible_netid])
      @user = User.new(ldap_result)

      # Does netID exist?
      if ldap_result.nil?
        @message = 'Sorry, the netID that you entered does not exist.
        You cannot create a user profile without a valid netID.'
        render :new and return
      end

      # Is there a user record already?
      if User.exists?(login: params[:possible_netid])
        @message = 'You cannot create a new user, as the netID you entered
        is already associated with a user. If you would like to reserve for
        them, please select their name from the drop-down options in the cart.'
        render :new and return
      end

      # With existing netID and no user record, what's the context of creation?
      # FIXME: can the check be replaced by params[:from_cart].present?
      if params[:from_cart] == 'true'
        @partial_to_render = 'short_form' # Display short_form
      else
        @partial_to_render = 'form' # Display (normal) form
      end
    end
  end

  def create
    @user = User.new(params[:user])
    @user.view_mode = @user.role
    # this line is what allows checkoutpeople to create users
    @user.login = session[:cas_user] unless current_user and can? :manage, Reservation
    if @user.save
      respond_to do |format|
        flash[:notice] = "Successfully created user."
        format.js {render action: 'create_success'}
      end
    else
      respond_to do |format|
        format.js {render :action => 'load_form_errors'}
      end
    end
  end

  def edit
    @can_edit_login = can? :edit_login, User
  end

  def update
    params[:user].delete(:login) unless can? :change_login, User #no changing login unless you're an admin
    params[:user][:view_mode] = params[:user][:role]
    if @user.update_attributes(params[:user])
      respond_to do |format|
        flash[:notice] = "Successfully updated user."
        format.js {render action: 'create_success'}
      end
    else
      respond_to do |format|
        format.js {render :action => 'load_form_errors'}
      end
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end

  def ban
    @user.role = "banned"
    @user.view_mode = "banned"
    @user.save
    flash[:notice] = "#{@user.name} was banned succesfully."
    redirect_to request.referer
  end

  def unban
    @user.role = "normal"
    @user.view_mode = "normal"
    @user.save
    flash[:notice] = "#{@user.name} was restored to patron status."
    redirect_to request.referer
  end

  def find
    if params[:fake_searched_id].blank?
      flash[:alert] = "Search field cannot be blank"
      redirect_to :back and return
    elsif params[:searched_id].blank?
      # this code is a hack to allow hitting enter in the search box to go direclty to the first user
      # and still user the rails3-jquery-autocomplete gem for the search box. Unfortunately the feature
      # isn't built into the gem.
      users = get_autocomplete_items(term: params[:fake_searched_id])
      if !users.blank?
        @user = users.first
        redirect_to manage_reservations_for_user_path(@user.id) and return
      else
        flash[:alert] = "Please select a valid user"
        redirect_to :back and return
      end
    else
      @user = User.find(params[:searched_id])
      redirect_to manage_reservations_for_user_path(@user.id) and return
    end
  end

end
