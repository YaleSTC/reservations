module CatalogHelper
  def prepare_pagination
    @default_user_per = @app_configs.default_per_cat_page.to_i unless @app_configs.default_per_cat_page.blank?

    session[:user_per_cat_page] ||= @default_user_per
    session[:user_per_cat_page] = params[:user_cat_items_per_page] if !params[:user_cat_items_per_page].blank?
    
    @paginated_equipment_models_by_category = EquipmentModel.order('categories.sort_order ASC, equipment_models.name ASC').includes(:category).page(params[:page]).per(session[:user_per_cat_page])
    @equipment_models_by_category = @paginated_equipment_models_by_category.to_a.group_by(&:category)
    @user_per_page_opts = [10, 20, 25, 30, 50].sort
    @user_per_page_opts = @user_per_page_opts.unshift(@default_user_per).sort if !@default_user_per.blank? && !@user_per_page_opts.include?(@default_user_per)
  end
end
