class EquipmentObjectsController < ApplicationController
  load_and_authorize_resource
  before_action :set_current_equipment_object, only: [:show, :edit, :update, :destroy, :deactivate, :activate]
  before_action :set_equipment_model_if_possible, only: [:index, :new]

  include ActivationHelper

  # ---------- before filter methods ---------- #

  def set_current_equipment_object
    @equipment_object = EquipmentObject.find(params[:id])
  end

  def set_equipment_model_if_possible
    @equipment_model = EquipmentModel.find(params[:equipment_model_id]) if params[:equipment_model_id]
  end

  # ---------- end before filter methods ---------- #

  #I'm not sure if there's ever a way @equipment_model could be set?
  def index
    if params[:show_deleted]
      @equipment_objects = ( @equipment_model  ? @equipment_model.equipment_objects : EquipmentObject.all )
    else
      @equipment_objects = ( @equipment_model  ? @equipment_model.equipment_objects.active : EquipmentObject.active )
    end
  end

  def show
  end

  def new
    @equipment_object = EquipmentObject.new(equipment_model: @equipment_model)
  end

  def create
    @equipment_object = EquipmentObject.new(eo_params)
    if @equipment_object.save
      flash[:notice] = "Successfully created equipment object. #{@equipment_object.serial}"
      redirect_to @equipment_object.equipment_model
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    p = eo_params
    if p[:deleted_at].blank?
      # Delete deactivation reason when "Disabled?" is toggled
      p[:deactivation_reason] = ""
    end

    if @equipment_object.update_attributes(p)
      flash[:notice] = "Successfully updated equipment object."
      redirect_to @equipment_object.equipment_model
    else
      render action: 'edit'
    end
  end

  # Deactivate and activate extend controller methods in ApplicationController
  def deactivate
    @equipment_object.update_attributes(deactivation_reason: params[:deactivation_reason])
    super
  end

  def activate
    super
    @equipment_object.update_attributes(deactivation_reason: nil)
  end

  private

  def eo_params
    params.require(:equipment_object).permit(:name, :serial, :equipment_model_id,
                                             :deleted_at, :deactivation_reason)
  end
end
