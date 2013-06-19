class CatalogController < ApplicationController
  helper :black_outs
  layout 'application_with_sidebar'

  before_filter :set_equipment_model, :only => [:add_to_cart, :remove_from_cart]

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
      format.js{render :action => "cat_pagination"}
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
    def change_cart(action, item)
      cart.send(action, item)

      errors = Reservation.validate_set(cart.reserver, cart.cart_reservations)
      flash[:error] = errors.to_sentence

      respond_to do |format|
        format.html{redirect_to root_path}
        format.js{render :action => "update_cart"}
      end
    end
end
