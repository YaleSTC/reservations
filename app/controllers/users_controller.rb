class UsersController < ApplicationController
  layout 'application_with_sidebar', only: [:show, :edit]
  
  #necessary to set up initial users and admins
  skip_filter :first_time_user, :only => [:new, :create]
  skip_filter :new_admin_user, :only => [:new, :create]
  skip_filter :app_setup, :only => [:new, :create]
  
  
  skip_filter :cart, :only => [:new, :create]
  before_filter :require_checkout_person, :only => :index
     
  require 'activationhelper'
  include ActivationHelper

  def index
    if params[:show_deleted]
      @users = User.include_deleted.find(:all, :order => 'login ASC')
    else
      @users = User.find(:all, :order => 'login ASC')
    end
  end

  def show
    @user = User.include_deleted.find(params[:id])
    require_user_or_checkout_person(@user)
    @user_reservations = @user.reservations
    @all_equipment = Reservation.active_user_reservations(@user)
    @show_equipment = { current_equipment: @user.reservations.select{|r| (r.status == "checked out") || (r.status == "overdue")}, 
                        current_reservations: @user.reservations.reserved, 
                        overdue_equipment: @user.reservations.overdue, 
                        past_equipment: @user.reservations.returned,
                        missed_reservations: @user.reservations.missed, 
                        past_overdue_equipment: @user.reservations.returned.select{|r| r.checked_in > r.due_date} }
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
    @user = User.include_deleted.find(params[:id])
    require_user(@user)
  end

  def update
    @user = User.include_deleted.find(params[:id])
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
    @user = User.include_deleted.find(params[:id])
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
      @user = User.include_deleted.find(params[:searched_id])
      require_user_or_checkout_person(@user)
      redirect_to manage_reservations_for_user_path(@user.id) and return
    end
  end
  
  def import
    #initialize
    @user_type = params[:user_type]
    file = params[:csv_upload]
    @users_added_set = []
    @users_updated_set = []
    @users_not_added_set = {}
    @users_not_updated_set = {}
    @users_conflict_set = {}
    flash[:errors] = ''
    
    # update existing users?
    if params[:overwrite] == '1'
      @overwrite = true
    else
      @overwrite = false
    end
    
    # the rails CSV class only handles filepaths and not file objects
    unless file.nil? # if the file has been uploaded
      location = file.tempfile.path
      users_hash = User.csv_import(location)
    else # if we're updating conflict users from the import_success page
      users_hash = params[:users_hash]
    end
    
    # make sure import didn't totally fail
    if users_hash.nil?
      flash[:error] = 'Unable to import CSV file. Please ensure it matches the import format, and try again.'
      redirect_to :back and return
    end
    
    users_hash.each do |user,data|      
      @user_formatted = User.csv_data_formatting(user,data,@user_type)
      
      # check validations and save
      # test size == 1 in case the admin tries any funny business (non-uniqueness) in the database
      if @overwrite and (User.where("login = ?", user).size == 1)
        @user = User.where("login = ?", user).first
        @user.csv_import = true

        if @user.update_attributes(@user_formatted)
          @users_updated_set << @user
          next
        else
          # attempt LDAP rescue
          ldap_hash = User.search_ldap(user)
          if ldap_hash.nil?
            data << 'Incomplete user information. Unable to find user in online directory (LDAP).'
            @users_not_updated_set[user] = data
            next
          end
          
          # redeclare what LDAP overwrote
          @user_formatted = User.import_ldap_fix(ldap_hash,user,data,@user_type)
          @user.csv_import = true
          
          # re-attempt save
          if @user.update_attributes(@user_formatted)
            @users_updated_set << @user
            next
          else
            data << process_all_error_messages_to_string(@user)
            @users_not_updated_set[user] = data
            next
          end
        end
      else
        @user = User.new(@user_formatted)
        @user.csv_import = true
        
        if @user.valid?
          @user.save
          @users_added_set << @user
          next
        else # if validations fail
          # attempt LDAP rescue
          ldap_hash = User.search_ldap(user)
          if ldap_hash.nil?
            data << 'Incomplete user information. Unable to find user in online directory (LDAP).'
            @users_not_added_set[user] = data
            next
          end
          
          # redeclare what LDAP overwrote
          @user_formatted = User.import_ldap_fix(ldap_hash,user,data,@user_type)
          
          @user = User.new(@user_formatted)
          @user.csv_import = true
          
          if @user.valid?
            @user.save
            @users_added_set << @user
            next
          else
            error_temp = process_all_error_messages_to_string(@user)
            if error_temp == 'Login has already been taken. '
              data << 'User already exists.'
              @users_conflict_set[user] = data
            else
              data << error_temp
              @users_not_added_set[user] = data
            end
          end
        end
      end
    end
    render 'import_success'
  end
  
  def import_page
    @select_options = [['Patrons','normal'],['Checkout Persons','checkout'],['Administrators','admin'],['Banned Users','banned']]
    render 'import'
  end

end
