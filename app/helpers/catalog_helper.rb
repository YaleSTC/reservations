module CatalogHelper
  def prepare_pagination
    array = []
    array << params[:items_per_page]
    array << session[:items_per_page]
    array << @app_configs.default_per_cat_page
    array << 10
    items_per_page = array.reject{ |a| a.blank? || a == 0 }.first
    # assign items per page to the passed params, the default or 10
    # depending on if they exist or not
    @page_eq_models_by_category = EquipmentModel.active.
                              order('categories.sort_order ASC, equipment_models.name ASC').
                              includes(:category).
                              page(params[:page]).
                              per(items_per_page)
    @eq_models_by_category = @page_eq_models_by_category.to_a.group_by(&:category)
    @per_page_opts = [10, 20, 25, 30, 50].unshift(items_per_page).uniq
    @pagination_required = EquipmentModel.active.size > items_per_page
    session[:items_per_page] = items_per_page
  end
end

