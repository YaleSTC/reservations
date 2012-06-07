class CatalogController < ApplicationController
  def index
    @equipment_models_by_category = EquipmentModel.not_deleted.order('categories.sort_order ASC, equipment_models.name ASC').includes(:category).group_by(&:category)
    #push accessories to bottom by removing and reinserting
    #@equipment_models_by_category[Category.find_by_name("Accessories")] = @equipment_models_by_category.delete(Category.find_by_name("Accessories"))
  end
  
  def add_to_cart
    @equipment_model = EquipmentModel.find(params[:id])
    cart.add_equipment_model(@equipment_model)
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js
    end
  rescue ActiveRecord::RecordNotFound 
    logger.error("Attempt to add invalid equipment model #{params[:id]}") 
    flash[:notice] = "Invalid equipment_model" 
    redirect_to root_path
  end
  
  def remove_from_cart
    @equipment_model = EquipmentModel.find(params[:id])
    cart.remove_equipment_model(@equipment_model)
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js
    end
  rescue ActiveRecord::RecordNotFound 
    logger.error("Attempt to remove invalid equipment model #{params[:id]}") 
    flash[:notice] = "Invalid equipment_model" 
    redirect_to root_path
  end
  
  def search
    if params[:category].nil?
      redirect_to catalog_path
    else
      #update dates
      session[:cart].set_start_date(Date.civil(params[:cart][:"start_date(1i)"].to_i,params[:cart][:"start_date(2i)"].to_i,params[:cart][:"start_date(3i)"].to_i))
      session[:cart].set_due_date(Date.civil(params[:cart][:"due_date(1i)"].to_i,params[:cart][:"due_date(2i)"].to_i,params[:cart][:"due_date(3i)"].to_i))
    
      @category = Category.find(params[:category])
      @equipment_models = @category.equipment_models.select{|e| e.available?(cart.start_date..cart.due_date)}
      @equipment_models_by_category = @equipment_models.sort_by(&:name).group_by(&:category)
    
      flash.now[:notice] = "The following #{@category.name.pluralize} are available from #{cart.start_date} to #{cart.due_date}:"
      render :action => :index
    end
  end
end
