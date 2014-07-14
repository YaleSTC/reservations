class CatalogController < ApplicationController
  layout 'application_with_sidebar'

  before_filter :set_equipment_model, only: [:add_to_cart, :remove_from_cart]

  # --------- before filter methods --------- #

  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    logger.error("Attempt to add invalid equipment model #{params[:id]}")
    flash[:notice] = "Invalid equipment_model"
    redirect_to root_path
  end

  # --------- end before filter methods --------- #


  def index
    @reserver_id = session[:cart].reserver_id
    prepare_pagination
    prepare_refresh_vars
  end

  def add_to_cart
    change_cart(:add_item, @equipment_model)
  end

  def remove_from_cart
    change_cart(:remove_item, @equipment_model)
  end

  def update_user_per_cat_page
    session[:user_per_cat_page] = params[:user_cat_items_per_page] if !params[:user_cat_items_per_page].blank?
    respond_to do |format|
      format.html{redirect_to root_path}
      format.js{render action: "cat_pagination"}
    end
  end

  def search
    if params[:query].blank?
      redirect_to root_path and return
    else
      @equipment_model_results = EquipmentModel.active.catalog_search(params[:query])
      @category_results = Category.catalog_search(params[:query])
      @equipment_object_results = EquipmentObject.catalog_search(params[:query])
      render 'search_results' and return
    end
  end

  private
    # this method is called to either add or remove an item from the cart
    # it takes either :add_item or :remove_item as an action variable,
    # and adds or removes the equipment_model set from params{} in the before_filter.
    # Finally, it renders the root page and runs the javascript to update the cart
    # (or displays the appropriate errors)
    def change_cart(action, item)
      cart.send(action, item)
      errors = cart.validate_all
      flash[:error] = errors.to_sentence
      flash[:notice] = "Cart updated."

      respond_to do |format|
        format.html{redirect_to root_path}
        format.js{render action: "update_cart"}
      end
    end

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
