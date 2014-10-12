class AppConfigsController < ApplicationController
  authorize_resource :class => false
  skip_before_filter :seen_app_configs, only: [:edit]

  def edit
    @app_config = AppConfig.first || AppConfig.new
    @app_config.update_attribute(:viewed, true)
  end

  def update
    @app_config = AppConfig.first

    reset_tos = params[:app_config][:reset_tos_for_users]

    if @app_config.update_attributes(app_config_params)
      if reset_tos == '1'
        User.update_all(['terms_of_service_accepted = ?', false])
      end

      # TODO: Does this work? Checkbox shouldn't have value of 'on'??
      if params[:restore_favicon] == 'on'
        @app_config.favicon = nil
        @app_config.save
      end

      flash[:notice] = "Application settings updated successfully."
      redirect_to catalog_path
    else
      # flash[:error] = "Error saving application settings."
      render action: 'edit'
    end
  end

  private

  def app_config_params
    params.require(:app_config)
          .permit(:site_title, :admin_email, :department_name, :contact_link_location,
                  :home_link_text, :home_link_location,
                  :upcoming_checkin_email_body, :upcoming_checkin_email_active,
                  :overdue_checkin_email_body, :overdue_checkin_email_active,
                  :reservation_confirmation_email_active,
                  :delete_missed_reservations, :send_notifications_for_deleted_missed_reservations,
                  :deleted_missed_reservation_email_body,
                  :default_per_cat_page, :terms_of_service, :favicon,
                  :checkout_persons_can_edit, :enable_renewals,
                  :override_on_create, :override_at_checkout, :require_phone,
                  :request_text)
  end
end

