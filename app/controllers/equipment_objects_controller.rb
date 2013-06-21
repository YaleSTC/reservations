class EquipmentObjectsController < ApplicationController
  before_filter :require_admin, :except => :index
  before_filter :require_checkout_person, :only => :index
  before_filter :set_current_equipment_object, :only => [:show, :edit, :update, :destroy]
  before_filter :set_equipment_model_if_possible, :only => [:index, :new]

  include ActivationHelper

  # ---------- before filter methods ---------- #

  def set_current_equipment_object
    @equipment_object = EquipmentObject.find(params[:id])
  end

  def set_equipment_model_if_possible
    @equipment_model = EquipmentModel.find(params[:equipment_model_id]) if params[:equipment_model_id]
  end

  # ---------- end before filter methods ---------- #


  def index
    if params[:show_deleted]
      @equipment_objects = ( @equipment_object ? @equipment_object.equipment_models : EquipmentObject.all )
    else
      @equipment_objects = ( @equipment_object ? @equipment_object.equipment_models.active : EquipmentObject.active )
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
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if @equipment_object.update_attributes(params[:equipment_object])
      flash[:notice] = "Successfully updated equipment object."
      redirect_to @equipment_object.equipment_model
    else
      render :action => 'edit'
    end
  end

  def destroy
    @equipment_model = @equipment_object.equipment_model #We need this so that we know where to re-direct (look down 4 lines)
    @equipment_object.destroy(:force)
    flash[:notice] = "Successfully destroyed equipment object."
    redirect_to @equipment_model
  end
end
