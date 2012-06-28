class ApplicationSetupController < ApplicationController
  before_filter :redirect_if_not_first_run
  before_filter :create_app_config
  before_filter :create_admin_user
  
  
  def create_app_config
    if @app_config.nil?
      AppConfig.create!({ :site_title => "Reservations",
                        :admin_email => "admin@admin.admin",
                       :department_name => "School of Art Digital Technology Office",
                       :contact_link_text => "Contact Us", 
                       :contact_link_location => "mailto:contact.us@change.com", 
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
  
  def create_admin_user
    if current_user.nil?
      flash[:notice] = "Hey there! Since this is your first time making a reservation, we'll
        need you to supply us with some basic contact information."
      redirect_to new_user_path
    end
  end  
  
  private
    def redirect_if_not_first_run
      if User.first
        flash[:error] = "The setup wizard can only be run on first launch."
        redirect_to root_path
      end
    end  
end
