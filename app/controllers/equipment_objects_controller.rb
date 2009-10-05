class EquipmentObjectsController < ApplicationController
  def index
    @equipment_objects = EquipmentObject.all
    if params[:equipment_model_id]
      @equipment_model = EquipmentModel.find(params[:equipment_model_id])
      @equipment_objects = @equipment_model.equipment_objects
    else
      @equipment_objects = EquipmentObject.all
    end
  end
  
  def show
    @equipment_object = EquipmentObject.find(params[:id])
  end
  
  def new
    @equipment_model = EquipmentModel.find(params[:equipment_model_id]) if params[:equipment_model_id]
    @equipment_object = EquipmentObject.new(:equipment_model => @equipment_model)
  end
  
  def create
    @equipment_object = EquipmentObject.new(params[:equipment_object])
    if @equipment_object.save
      flash[:notice] = "Successfully created equipment object."
      redirect_to @equipment_object.equipment_model
    else
      render :action => 'new'
    end
  end
  
  def edit
    @equipment_object = EquipmentObject.find(params[:id])
  end
  
  def update
    @equipment_object = EquipmentObject.find(params[:id])
    if @equipment_object.update_attributes(params[:equipment_object])
      flash[:notice] = "Successfully updated equipment object."
      redirect_to @equipment_object.equipment_model
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @equipment_object = EquipmentObject.find(params[:id])
    @equipment_object.destroy
    flash[:notice] = "Successfully destroyed equipment object."
    redirect_to equipment_objects_url
  end
end
