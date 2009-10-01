class UsersController < ApplicationController
  skip_before_filter :first_time_user, :only => [:new, :create]
  before_filter :require_admin, :only => :index
  
  def index
    @users = User.all
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
    @user = User.new(User.search_ldap(session[:cas_user]))
    @user.login = session[:cas_user] #default to current user
  end
  
  def create
    @user = User.new(params[:user])
    @user.login = session[:cas_user]
    @user.is_admin = true if User.count == 0
    if @user.save
      flash[:notice] = "Successfully created user."
      redirect_to @user
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
    @user.login = session[:cas_user] unless current_user.is_admin?
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
