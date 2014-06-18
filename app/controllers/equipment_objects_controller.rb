class EquipmentObjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :set_current_equipment_object, only: [:show, :edit, :update, :destroy, :deactivate, :reactivate]
  before_filter :set_equipment_model_if_possible, only: [:index, :new]

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
    @equipment_object = EquipmentObject.new(params[:equipment_object])
    if @equipment_object.serial == "Enter serial # (optional)"
      @equipment_object.serial = nil
    end
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
    if @equipment_object.update_attributes(params[:equipment_object])
      flash[:notice] = "Successfully updated equipment object."
      redirect_to @equipment_object.equipment_model
    else
      render action: 'edit'
    end
  end

  def destroy
    @equipment_model = @equipment_object.equipment_model #We need this so that we know where to re-direct (look down 4 lines)
    @equipment_object.destroy(:force)
    flash[:notice] = "Successfully destroyed equipment object."
    redirect_to @equipment_model
  end

  def deactivate
    if @equipment_object.update_attributes(deactivated: true, deactivation_reason: params[:deactivation_reason])
      flash[:notice] = "Successfully deactivated equipment object with reason: #{params[:deactivation_reason]}."
    else
      flash[:error] = "Deactivation of equipment object failed."
    end
    redirect_to @equipment_object.equipment_model
  end

  def reactivate
    if @equipment_object.update_attributes(deactivated: false, deactivation_reason: nil)
      flash[:notice] = "Successfully reactivated equipment object."
    else
      flash[:error] = "Reactivation of equipment object failed."
    end
    redirect_to @equipment_object.equipment_model
  end
end
