class UsersController < ApplicationController
  layout 'application_with_sidebar', only: [:show, :edit]

  #necessary to set up initial users and admins
  skip_filter :first_time_user, :only => [:new, :create]
  skip_filter :new_admin_user, :only => [:new, :create]
  skip_filter :app_setup, :only => [:new, :create]


  skip_filter :cart, :only => [:new, :create]
  before_filter :require_checkout_person, :only => :index
  before_filter :set_user, :only => [:show, :edit, :update, :destroy]

  require 'activationhelper'
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
    if current_user and current_user.is_admin_in_adminmode?
      @user = User.new
    else
      @user = User.new(User.search_ldap(session[:cas_user]))
      @user.login = session[:cas_user] #default to current login
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = session[:cas_user] unless current_user and current_user.can_checkout?
    @user.is_admin = true if User.count == 0
    if @user.save
      respond_to do |format|
        flash[:notice] = "Successfully created user."
        format.js {render :action => 'create_success'}
      end
    else
      respond_to do |format|
        format.js {render :action => 'load_validations'}
      end
    end
  end

  def edit
    require_user(@user)
  end

  def update
    require_user(@user)
    params[:user].delete(:login) unless current_user.is_admin_in_adminmode? #no changing login unless you're an admin
    if @user.update_attributes(params[:user])
      respond_to do |format|
        flash[:notice] = "Successfully updated user."
        format.js {render :action => 'create_success'}
      end
    else
      respond_to do |format|
        format.js {render :action => 'load_validations'}
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
      flash[:alert] = "Please select a valid user"
      redirect_to :back and return
    else
      @user = User.find(params[:searched_id])
      require_user_or_checkout_person(@user)
      redirect_to manage_reservations_for_user_path(@user.id) and return
    end
  end

  def import
    unless current_user.is_admin_in_adminmode?
      flash[:error] = 'Permission denied.'
      redirect_to root_path and return
    end

    # initialize
    file = params[:csv_upload] # the file object
    user_type = params[:user_type]
    overwrite = (params[:overwrite] == '1') # update existing users?
    filepath = file.tempfile.path # the rails CSV class needs a filepath

    imported_users = csv_import(filepath)

    # check if input file is valid and return appropriate error message if not
    if valid_input_file?(imported_users)
      # create the users and exit
      @hash_of_statuses = User.import_users(imported_users,overwrite,user_type)
      render 'import_success'
    end
  end

  def import_page
    @select_options = [['Patrons','normal'],['Checkout Persons','checkout'],['Administrators','admin'],['Banned Users','banned']]
    render 'import'
  end

  private

    def valid_input_file?(imported_users)

      # make sure import from CSV didn't totally fail
      if imported_users.nil?
        flash[:error] = 'Unable to import CSV file. Please ensure it matches the import format, and try again.'
        redirect_to :back and return
      end

      # make sure we have login data (otherwise all will always fail)
      unless imported_users.first.keys.include?(:login)
        flash[:error] = "Unable to import CSV file. None of the users will be able to log in without specifying 'login' data."
        redirect_to :back and return
      end

      # make sure the import went with proper headings / column handling
      accepted_keys = [:login, :first_name, :last_name, :nickname, :phone, :email, :affiliation]
      unless imported_users.first.keys == accepted_keys
        flash[:error] = 'Unable to import CSV file. Please ensure that the first line of the file exactly matches the sample input (login, first_name, etc.) Note that headers are case sensitive and must be in the correct order.'
        redirect_to :back and return
      end
    end

end
