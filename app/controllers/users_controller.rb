class UsersController < ApplicationController
  skip_before_filter :first_time_user, :only => [:new, :create]
  before_filter :require_admin, :only => :index

  def index
    @users = User.find(:all, :order => 'login ASC')
  end

  def show
    @user = User.find(params[:id])
    require_user(@user)
    @all_equipment = Reservation.active_user_reservations(@user)
  end

  def new
    if current_user and current_user.is_admin?
      @user = User.new
    else
      @user = User.new(User.search_ldap(session[:cas_user]))
      binding.pry
      @user.login = session[:cas_user] #default to current login
    end
  end

  def create
    @user = User.new(params[:user])
    @user.login = session[:cas_user] unless current_user and current_user.is_admin?
    @user.is_admin = true if User.count == 0
    if @user.save
      flash[:notice] = "Successfully created user."
      redirect_to (current_user.is_admin? ? @user : root_path)
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
    params[:user].delete(:login) unless current_user.is_admin? #no changing login unless you're an admin
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user."
      redirect_to @user
    else
      render :action => 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end
end

