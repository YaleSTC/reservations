class CatalogController < ApplicationController
  layout 'application_with_sidebar'

  before_filter :set_equipment_model, only: [:add_to_cart, :remove_from_cart]
  skip_before_filter :authenticate_user!

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
    prepare_catalog_index_vars
  end

  def add_to_cart
    change_cart(:add_item, @equipment_model)
  end

  def remove_from_cart
    change_cart(:remove_item, @equipment_model)
  end

  def update_user_per_cat_page
    session[:items_per_page] = params[:items_per_page] if !params[:items_per_page].blank?
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
      prepare_catalog_index_vars(@equipment_model_results)
      render 'search_results' and return
    end
  end

  def deactivate
    if params[:deactivation_cancelled]
      flash[:notice] = 'Deactivation cancelled.'
      redirect_to categories_path
    elsif params[:deactivation_confirmed]
      super
    else
      flash[:error] = 'Oops, something went wrong.'
      redirect_to categories_path
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
        format.js{render template: "cart_js/update_cart"}
      end
    end

  def prepare_pagination
    array = []
    array << params[:items_per_page].to_i
    array << session[:items_per_page].to_i
    array << @app_configs.default_per_cat_page
    array << 10
    items_per_page = array.reject{ |a| a.blank? || a == 0 }.first
    # assign items per page to the passed params, the default or 10
    # depending on if they exist or not
    @per_page_opts = [10, 20, 25, 30, 50].unshift(items_per_page).uniq
    session[:items_per_page] = items_per_page
  end


end
