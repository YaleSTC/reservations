class UsersController < ApplicationController
  load_and_authorize_resource
  layout 'application_with_sidebar', only: [:show, :edit]

  skip_filter :cart, only: [:new, :create]
  skip_filter :first_time_user, only: [:new, :create]
  before_filter :set_user, only: [:show, :edit, :update, :destroy, :deactivate, :activate]

  include ActivationHelper
  include Autocomplete

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
    if can? :create, User
      if params[:possible_netid]
        @user = User.new(User.search_ldap(params[:possible_netid]))
      else
        @user = User.new
      end
    else
      @user = User.new(User.search_ldap(session[:cas_user]))
      @user.login = session[:cas_user] #default to current login
    end
    @can_edit_login = (can? :create, User)
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
    @user.destroy(:force)
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
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

  def deactivate
    @user.destroy #Deactivate the user model
    flash[:notice] = "Successfully deactivated user. Any related equipment has been deactivated as well. All reservations for this user have been permanently destroyed."
    redirect_to users_path  # always redirect to show page for deactivated user
  end

  def activate
    @user.revive
    flash[:notice] = "Successfully reactivated user."
    redirect_to users_path
  end
end
