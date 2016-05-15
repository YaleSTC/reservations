RailsAdmin.config do |config|
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
  config.authorize_with :cancan

  ## == PaperTrail ==
  # PaperTrail >= 3.0.0
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version'

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    # delete
    show_in_app
    # modified delete method to deal with objects with soft deletion
    member :force_delete, :delete do
      i18n_key :delete
      controller do
        proc do
          if request.get? # DELETE

            respond_to do |format|
              format.html { render @action.template_name }
              format.js   { render @action.template_name, layout: false }
            end

          elsif request.delete? # DESTROY
            # optionally pass the force parameter
            opt = :force if @object.has_attribute?(:deleted_at)

            redirect_path = nil
            @auditing_adapter &&
              @auditing_adapter.delete_object(@object, @abstract_model,
                                              _current_user)
            if @object.send(:destroy, opt)
              flash[:success] = t('admin.flash.successful',
                                  name: @model_config.label,
                                  action: t('admin.actions.delete.done'))
              redirect_path = index_path
            else
              flash[:error] = t('admin.flash.error',
                                name: @model_config.label,
                                action: t('admin.actions.delete.done'))
              redirect_path = back_or_index
            end

            redirect_to redirect_path
          end
        end
      end
    end

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  # Include only models we care about
  config.included_models =
    [Announcement, AppConfig, Blackout, Category, CheckinProcedure,
     CheckoutProcedure, EquipmentModel, EquipmentItem, Requirement,
     Reservation, User]
end
