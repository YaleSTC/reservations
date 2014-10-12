class UsersController < ApplicationController
  load_and_authorize_resource
  layout 'application_with_sidebar', only: [:show, :edit]

  autocomplete :user, :last_name, extra_data: [:first_name, :username], display_value: :render_name

  skip_filter :cart, only: [:new, :create]
  skip_filter :first_time_user, only: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :ban, :unban]

  include Autocomplete

  # ------------ before filter methods ------------ #

  def set_user
    @user = User.find(params[:id])
  end

  # ------------ end before filter methods ------------ #


  def index
    if params[:show_banned]
      @users = User.order('username ASC')
    else
      @users = User.active.order('username ASC')
    end
  end

  def show
    @user_reservations = @user.reservations
    @all_equipment = Reservation.active.for_reserver(@user)
    @show_equipment = { checked_out:  @user_reservations.checked_out,
                        overdue:      @user_reservations.overdue,
                        future:       @user_reservations.reserved,
                        past:         @user_reservations.returned,
                        missed:       @user_reservations.missed,
                        past_overdue: @user_reservations.returned_overdue }
  end

  def new
    @can_edit_username = current_user.present? && (can? :create, User) # used in view
    if current_user.nil?
      # This is a new user -> create an account for them
      @user = User.new(User.search_ldap(session[:cas_user]))
      @user.username = session[:cas_user] #default to current username
    else
      @user = User.new
    end
  end

  def create
    @user = User.new(user_params)
    @user.role = 'normal' if user_params[:role].blank?
    @user.view_mode = @user.role
    @user.username = session[:cas_user] unless current_user and can? :manage, Reservation
    if @user.save
      flash[:notice] = "Successfully created user."
      redirect_to user_path(@user)
    else
      @can_edit_username = current_user.present? && (can? :create, User) # used in view
      render :new
    end
  end

  def quick_new
    ldap_result = User.search_ldap(params[:possible_netid])
    @user = User.new(ldap_result)

    # Does netID exist?
    if ldap_result.nil?
      @message = 'Sorry, the netID that you entered does not exist.
      You cannot create a user profile without a valid netID.'
      render :quick_new and return
    end

    # Is there a user record already?
    if User.find_by_username(params[:possible_netid])
      @message = 'You cannot create a new user, as the netID you entered
      is already associated with a user. If you would like to reserve for
      them, please select their name from the drop-down options in the cart.'
      render :quick_new and return
    end
  end

  def quick_create
    @user = User.new(user_params)
    @user.role = 'normal' if user_params[:role].blank?
    @user.view_mode = @user.role
    if @user.save
      render action: 'create_success'
    else
      render action: 'load_form_errors'
    end
  end


  def edit
    @can_edit_username = can? :edit_username, User
  end

  def update
    if @user.update_attributes(user_params)
      flash[:notice] = "Successfully updated user."
      redirect_to user_path(@user)
    else
      render :edit
    end
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

  private

  def user_params
    permitted_attributes = [:first_name, :last_name, :nickname, :phone, :email, :affiliation, :terms_of_service_accepted, :created_by_admin]
    permitted_attributes << :username if (can? :manage, Reservation)
    permitted_attributes += [:requirement_ids, :user_ids, :role] if can? :assign, :requirements
    p = params.require(:user).permit(*permitted_attributes)
    p[:view_mode] = p[:role] if p[:role]
    p
  end

end
