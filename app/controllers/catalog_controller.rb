class CatalogController < ApplicationController
  def index
    @equipment_models_by_category = EquipmentModel.find(:all, :include => :category, :order => 'categories.name ASC, equipment_models.name ASC').group_by(&:category)
  end
  
  def add_to_cart
    @equipment_model = EquipmentModel.find(params[:id])
    cart.add_equipment_model(@equipment_model)
    redirect_to root_path
  rescue ActiveRecord::RecordNotFound 
    logger.error("Attempt to add invalid equipment model #{params[:id]}") 
    flash[:notice] = "Invalid equipment_model" 
    redirect_to root_path
  end
  
  def remove_from_cart
    @equipment_model = EquipmentModel.find(params[:id])
    cart.remove_equipment_model(@equipment_model)
    redirect_to root_path
  rescue ActiveRecord::RecordNotFound 
    logger.error("Attempt to remove invalid equipment model #{params[:id]}") 
    flash[:notice] = "Invalid equipment_model" 
    redirect_to root_path
  end
end
