class UsersController < ApplicationController
  layout 'application_with_sidebar', only: [:show, :edit]

  #necessary to set up initial users and admins
  skip_filter :first_time_user, :only => [:new, :create]
  skip_filter :new_admin_user, :only => [:new, :create]
  skip_filter :app_setup, :only => [:new, :create]


  skip_filter :cart, :only => [:new, :create]
  before_filter :require_checkout_person, :only => :index
  before_filter :set_user, :only => [:show, :edit, :update, :destroy, :deactivate, :activate]

  include ActivationHelper

  # ------------ before filter methods ------------ #

  def set_user
    @user = User.find(params[:id])
  end

  # ------------ end before filter methods ------------ #


  def index
    if params[:show_deleted]
      @users = User.order('login ASC')
    else
      @users = User.active.order('login ASC')
    end
  end

  def show
    require_user_or_checkout_person(@user)
    @user_reservations = @user.reservations
    @all_equipment = Reservation.active_user_reservations(@user)
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
    if current_user and current_user.is_admin?(:as => 'admin')
      @user = User.new
    else
      @user = User.new(User.search_ldap(session[:cas_user]))
      @user.login = session[:cas_user] #default to current login
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = session[:cas_user] unless current_user and current_user.can_checkout?
    @user.role = 'admin' if User.count == 0
    if @user.save
      flash[:notice] = "Successfully created user."
      render :action => 'create_success'
    else
      render :action => 'load_validations'
    end
  end

  def edit
    require_user(@user)
  end

  def update
    require_user(@user)
    params[:user].delete(:login) unless current_user.is_admin?(:as => 'admin') #no changing login unless you're an admin
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user."
      render :action => 'create_success'
    else
      render :action => 'load_validations'
    end
  end

  def destroy
    @user.destroy(:force)
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end

  def find
    if params[:fake_searched_id].blank?
      flash[:alert] = "Search field cannot be blank"
      redirect_to :back and return
    elsif params[:searched_id].blank?
      flash[:alert] = "Please select a valid user"
      redirect_to :back and return
    else
      @user = User.find(params[:searched_id])
      require_user_or_checkout_person(@user)
      redirect_to manage_reservations_for_user_path(@user.id) and return
    end
  end

  def deactivate
    @user.destroy #Deactivate the model you had originally intended to deactivate
    flash[:notice] = "Successfully deactivated user. Any related reservations or equipment have been deactivated as well."
    redirect_to users_path  # always redirect to show page for deactivated user
  end

  def activate
    @user.revive
    flash[:notice] = "Successfully reactivated user. Any related reservations or equipment have been reactivated as well."
    redirect_to users_path
  end
end
