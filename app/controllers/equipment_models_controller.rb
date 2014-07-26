class EquipmentModelsController < ApplicationController
  layout 'application_with_sidebar', only: :show
  load_and_authorize_resource
  before_action :set_equipment_model, only: [:show, :edit, :update, :destroy]
  before_action :set_category_if_possible, only: [:index, :new]

  include ActivationHelper

  # --------- before filter methods --------- #
  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  end
  def set_category_if_possible
    @category = Category.find(params[:category_id]) if params[:category_id]
  end
  # --------- end before filter methods --------- #


  def index
    if params[:show_deleted]
      @equipment_models = ( @category ? @category.equipment_models : EquipmentModel.all )
    else
      @equipment_models = ( @category ? @category.equipment_models.active : EquipmentModel.active )
    end
  end

  def show
    @associated_equipment_models = @equipment_model.associated_equipment_models.sample(6)

    calendar_length = 1.month

    @reservation_data = []
    Reservation.active.for_eq_model(@equipment_model).each do |r|
      @reservation_data << {
        start: r.start_date,
        end: (r.status == 'overdue' ? Date.current + calendar_length : r.due_date) }
      # the above code mimics the current available? setup to show overdue
      # equipment as permanently 'out'.
    end

    @blackouts = []
    Blackout.active.each do |b|
      @blackouts << {
        start: b.start_date, end: b.end_date}
    end
    @date = Time.current.to_date
    @date_max = @date + calendar_length - 1.week
    @max = @equipment_model.equipment_objects.active.count

    @restricted = @equipment_model.model_restricted?(cart.reserver_id)
  end

  def new
    @equipment_model = EquipmentModel.new(category: @category)
  end

  def create
    @equipment_model = EquipmentModel.new(em_params)
    if @equipment_model.save
      flash[:notice] = "Successfully created equipment model."
      redirect_to @equipment_model
    else
      flash[:error] = "Please review the errors below. "
      render action: 'new'
    end
  end

  def edit
  end

  def delete_files
    # for a given filetype affected by param value, the file in question is saved in path contained value
    types = {"clear_documentation" => "documentations", "clear_photo" => "photos"}

    # only keep pairs that occur as keys with non-nil values in params
    types.select! {|k,v| params.keys.member? (k) and !v.nil?}
    types.each do |k,path|
      # TODO: investigate a way to do this without hard-coded paths
      # recursively remove files from filesystem
      file_location = Rails.root.to_s + "/public/attachments/equipment_models/" + path + "/" + @equipment_model.id.to_s + "/original/"
      FileUtils.rm_r file_location
      @equipment_model.documentation_file_name = NIL
    end
  end

  def update
    delete_files

    if @equipment_model.update_attributes(em_params)
      # hard-delete any deleted checkin/checkout procedures
      delete_procedures(params, "checkout")
      delete_procedures(params, "checkin")
      flash[:notice] = "Successfully updated equipment model."
      redirect_to @equipment_model
    else
      render action: 'edit'
    end
  end

  private

    # function to check for deleted checkin/checkout procedures and hard-delete them after equipment model update
    def delete_procedures(params, phase)
      # phase needs to be equal to either "checkout" or "checkin"
      phase_params = params[:equipment_model][:"#{phase}_procedures_attributes"]
      unless phase_params.nil?
        phase_params.each do |k, v|
          if v["id"] and v["_destroy"] != "false"
            @equipment_model.send(:"#{phase}_procedures")[k.to_i].destroy(:force)
          end
        end
      end
    end

    def em_params
      params.require(:equipment_model).
             permit(:name, :category_id, :category, :description, :late_fee,
                    :replacement_fee, :max_per_user, :document_attributes,
                    :deleted_at, :checkout_procedures_attributes,
                    :checkin_procedures_attributes, :photo, :documentation,
                    :max_renewal_times, :max_renewal_length,
                    :renewal_dats_before_due, :associated_equipment_model_ids,
                    :requirement_ids, :requirements)
    end
end
