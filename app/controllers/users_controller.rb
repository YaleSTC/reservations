class UsersController < ApplicationController
  #necessary to set up initial users and admins
  skip_filter :first_time_user, :only => [:new, :create]
  skip_filter :new_admin_user, :only => [:new, :create]
  skip_filter :app_setup, :only => [:new, :create]
  
  
  skip_filter :cart, :only => [:new, :create]
  before_filter :require_admin, :only => :index
     
  require 'activationhelper'
  include ActivationHelper

  def index
    if params[:show_deleted]
      @users = User.include_deleted.find(:all, :order => 'login ASC')
    else
      @users = User.find(:all, :order => 'login ASC')
    end
  end


  #from what I can see this code does nothing... uncomment if I am wrong
  #def new_button
    #@user = User.new
    #respond_to do |format|
      #format.html{redirect_to root_path}
      #format.js{render :action => "fancybox_new_user"}
    #end
  #end

  def show
    @user = User.include_deleted.find(params[:id])
    require_user(@user)
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
    @user.login = session[:cas_user] unless current_user and (current_user.is_admin_in_adminmode? or current_user.is_admin_in_checkoutpersonmode? or current_user.is_checkout_person?)
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
      flash[:notice] = "Successfully updated user."
      redirect_to @user
    else
      render :action => 'edit'
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
      redirect_to :back
    elsif params[:searched_id].blank?
      flash[:alert] = "Please select a valid user"
      redirect_to :back
    else
      @user = User.include_deleted.find(params[:searched_id])
    require_user(@user)
    redirect_to show_all_reservations_for_user_path({:user_id => @user.id})
    end
  end

end
