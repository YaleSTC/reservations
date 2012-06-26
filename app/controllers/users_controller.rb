class UsersController < ApplicationController
  skip_before_filter :first_time_user, :only => [:new, :create]
  skip_before_filter :cart, :only => [:new, :create]
  before_filter :require_admin, :only => :index

  def index
    if params[:show_deleted]
      @users = User.find(:all, :order => 'login ASC')
    else
      @users = User.not_deleted.find(:all, :order => 'login ASC')
    end
  end

  def new_button
    @user = User.new
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render :action => "fancybox_new_user"}
    end
  end

  def show
    @user = User.find(params[:id])
    require_user(@user)
    @all_equipment = Reservation.active_user_reservations(@user)
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
      flash[:notice] = "Successfully created user."
#   redirect to New Reservations page iff logged in as admin or
#   checkout person
      redirect_to ((current_user.is_admin_in_adminmode? or current_user.is_admin_in_checkoutpersonmode? or current_user.is_checkout_person?) ? @user : root_path)
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    require_user(@user)
  end

  def update
    @user = User.find(params[:id])
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
    @user = User.find(params[:id])
    @user.destroy(:force)
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end

end
