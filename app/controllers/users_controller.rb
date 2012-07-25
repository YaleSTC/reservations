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
    # the rails CSV class only handles filepaths and not file objects
    location = file.tempfile.path
    @users_added_set = []
    @users_not_added_set = {}
    flash[:errors] = ''
    
    users_hash = User.csv_import(location)
    
    # make sure import didn't totally fail
    if users_hash.nil?
      flash[:error] = 'Unable to import CSV file. Please ensure it matches the import format below.'
      redirect_to :back and return
    end
    
    users_hash.each do |user,data|      
      @user_temp = User.csv_data_formatting(user,data)
      @user = User.new(@user_temp)
      
      # assign user type
      if @user_type == 'admin'
        @user.is_admin = 1
      elsif @user_type == 'checkout'
        @user.is_checkout_person = 1
      elsif @user_type == 'normal'
        # add something if we change how type is stored in the database
      elsif @user_type == 'banned'
        @user.is_banned = 1
      end
      
      # check validations
      if @user.valid?
        # save
        @user.save
        @users_added_set << @user
        next
      else # if validations fail
        # check LDAP
        @user_temp = User.search_ldap(user)
        if @user_temp.nil?
          data << 'CSV import failed. User not found in LDAP rescue attempt.'
          @users_not_added_set[user] = data
          next
        end
        
        @user = User.new(@user_temp)
        
        # redeclare all the things that were overwritten by LDAP
        @user.first_name = data[0] unless data[0].blank?
        @user.last_name = data[1] unless data[1].blank?
        if @user.nickname.nil? or !data[2].blank?
          # preserve nicknames if defined; and ensure not NIL
          @user.nickname = data[2]
        end
        @user.phone = data[3] # LDAP doesn't fetch phone numbers
        @user.email = data[4] unless data[4].blank?
        @user.affiliation = data[5] unless data[5].blank?

        # assign user type
        if @user_type == 'admin'
          @user.is_admin = 1
        elsif @user_type == 'checkout'
          @user.is_checkout_person = 1
        elsif @user_type == 'normal'
          # add something if we change how type is stored in the database
        elsif @user_type == 'banned'
          @user.is_banned = 1
        end

        if @user.valid?
          @user.save
          @users_added_set << @user
          next
        else
          # process errors!
          data << process_all_error_messages_to_string(@user)
          @users_not_added_set[user] = data
        end
      end
    end
    render 'import_success'
  end
  
  def import_page
    @select_options = [['Normal Users','normal'],['Checkout Persons','checkout'],['Admins','admin'],['Banned Users','banned']]
    render 'import'
  end

end
