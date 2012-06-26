class CatalogController < ApplicationController
  def index
    @default_user_per = Settings.default_per_cat_page.to_i

    session[:user_per_cat_page] ||= @default_user_per
    session[:user_per_cat_page] = params[:user_cat_items_per_page] if !params[:user_cat_items_per_page].blank?

    @paginated_equipment_models_by_category = EquipmentModel.not_deleted.order('categories.sort_order ASC, equipment_models.name ASC').includes(:category).page(params[:page]).per(session[:user_per_cat_page])
    @equipment_models_by_category = @paginated_equipment_models_by_category.to_a.group_by(&:category)
    @user_per_page_opts = [10, 20, 25, 30, 50].sort
    @user_per_page_opts = @user_per_page_opts.unshift(@default_user_per).sort if !@default_user_per.blank? && !@user_per_page_opts.include?(@default_user_per)


    #push accessories to bottom by removing and reinserting
    #@equipment_models_by_category[Category.find_by_name("Accessories")] = @equipment_models_by_category.delete(Category.find_by_name("Accessories"))
  end

  def add_to_cart
    @equipment_model = EquipmentModel.find(params[:id])
    cart.add_equipment_model(@equipment_model)
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render :action => "update_cart"}
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
      format.js{render :action => "update_cart"}
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
      session[:cart].set_start_date(Date.strptime(params[:cart][:start_date_quicksearch],'%m/%d/%Y'))
      session[:cart].set_due_date(Date.strptime(params[:cart][:due_date_quicksearch],'%m/%d/%Y'))
      if !cart.valid_dates?
        flash[:error] = cart.errors.values.flatten.join("<br/>").html_safe
        cart.errors.clear
        redirect_to root_path
      else
        @category = Category.find(params[:category])
        @equipment_models = @category.equipment_models.select{|e| e.available?(cart.start_date..cart.due_date)}
        @equipment_models_by_category = @equipment_models.sort_by(&:name).group_by(&:category)

        flash.now[:notice] = "The following #{@category.name.pluralize} are available from #{cart.start_date} to #{cart.due_date}:"
        render :action => :index
      end
    end
  end
  
  def update_user_per_cat_page
    session[:user_per_cat_page] = params[:user_cat_items_per_page] if !params[:user_cat_items_per_page].blank?
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render :action => "cat_pagination"}
    end
  end
  
end
