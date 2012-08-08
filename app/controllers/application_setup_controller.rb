class ApplicationSetupController < ApplicationController
  helper :app_configs
  skip_filter :first_time_user
  skip_filter :app_setup

  before_filter :initialize_app_configs
  before_filter :load_configs
  before_filter :new_admin_user
  before_filter :redirect_if_not_first_run


  def new_admin_user
    flash[:notice] = "Welcome to Reservations! Create your user and you will be guided
                      through a setup to get your application up and running."
    if current_user and current_user.is_admin_in_adminmode?
       @user = User.new
     else
       @user = User.new(User.search_ldap(session[:cas_user]))
       @user.login = session[:cas_user] #default to current login
     end
   end

  def create_admin_user
    @user = User.new(params[:user])
    @user.login = session[:cas_user] unless current_user and current_user.can_checkout?
    @user.is_admin = true
    if @user.save
      flash[:notice] = "Successfully created Admin."
      redirect_to new_app_configs_path
    else
      render :action => 'new_admin_user'
    end
  end

  def load_configs
    @app_configs = AppConfig.first
  end

  def initialize_app_configs
     if AppConfig.all.empty?
       AppConfig.create!({ :site_title => "Reservations",
                           :admin_email => "admin@admin.admin",
                           :department_name => "School of Art Digital Technology Office",
                           :contact_link_location => "admin@admin.admin",
                           :home_link_text => "Home",
                           :home_link_location => "http://clc.yale.edu",
                           :default_per_cat_page => 20,
                           :upcoming_checkin_email_body => "Dear @user@,
                           Please remember to return the equipment you borrowed from us:

                           @equipment_list@

                           If the equipment is returned after 4 pm on @return_date@ you will be charged a late fee or replacement fee. Repeated late returns will result in the privilege to make further reservations for the rest of the term to be revoked.

                           Thank you,
                           @department_name@",
                           :overdue_checkout_email_body => "Dear @user@,
                           You have missed a scheduled equipment checkout, so your equipment may be released and checked out to other students.

                           Thank you,
                           @department_name@",
                           :overdue_checkin_email_body => "Dear @user@,
                           You were supposed to return the equipment you borrowed from us on @return_date@ but because you have failed to do so, you will be charged @late_fee@ / day until the equipment is returned. Failure to return equipment will result in replacement fees and revocation of borrowing privileges.

                           Thank you,
                           @department_name@"
                           })
     end
   end

   def new_app_configs
     flash[:notice] = "Edit your application settings here."
     @app_config = AppConfig.first
   end

   def create_app_configs
     @app_config = AppConfig.first
      if @app_config.update_attributes(params[:app_config])
        flash[:notice] = "Application settings updated successfully."
        redirect_to root_path
      else
        flash[:error] = "Error saving application settings."
        redirect_to :action => 'edit'
      end
  end

  private
    def redirect_if_not_first_run
      if User.all.count > 1
        flash[:error] = "The setup wizard can only be run on first launch."
        redirect_to root_path
      end
    end
end
