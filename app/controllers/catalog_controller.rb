# frozen_string_literal: true

# rubocop:disable ClassLength
class CatalogController < ApplicationController
  helper ReservationsHelper # for request_text
  layout 'application_with_sidebar'

  before_action :set_equipment_model, only:
    %i[add_to_cart remove_from_cart edit_cart_item]
  skip_before_action :authenticate_user!, unless: :guests_disabled?

  # --------- before filter methods --------- #

  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    logger.error("Attempt to add invalid equipment model #{params[:id]}")
    flash[:notice] = 'Invalid equipment_model'
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

  def edit_cart_item
    change_cart(:edit_cart_item, @equipment_model, params[:quantity].to_i)
  end

  def update_user_per_cat_page
    if params[:items_per_page].present?
      session[:items_per_page] = params[:items_per_page]
    end
    respond_to do |format|
      format.html { redirect_to root_path }
      format.js { render action: 'cat_pagination' }
    end
  end

  # this method updates item quantities using the edit_reservation_form
  def submit_cart_updates_form # rubocop:disable MethodLength, AbcSize
    flash.clear
    quantity = params[:quantity].to_i
    id = params[:id].to_i
    equipment_model = EquipmentModel.find(id)
    cart.send(:edit_cart_item, equipment_model, quantity)
    @errors = cart.validate_all # update the errors
    respond_to do |format|
      format.html do
        if cart.items.empty?
          redirect_to root_path
        else
          redirect_to new_reservation_path
        end
      end
      format.js do
        if cart.items.empty?
          # redirects to catalog page
          render inline: "window.location = '#{root_path}'"
        else
          # to prepare for making reservation
          @reservation = Reservation.new(start_date: cart.start_date,
                                         due_date: cart.due_date,
                                         reserver_id: cart.reserver_id)
          render template: 'cart_js/reservation_form'
        end
      end
    end
  end

  # called to update the dates in cart and trigger errors
  def change_reservation_dates
    flash.clear
    update_cart
    @errors = cart.validate_all # update the errors
    respond_to do |format|
      format.html { redirect_to new_reservation_path }
      format.js do
        # to prepare for making reservation
        @reservation = Reservation.new(start_date: cart.start_date,
                                       due_date: cart.due_date,
                                       reserver_id: cart.reserver_id)
        render template: 'cart_js/reservation_form'
      end
    end
  end

  def search
    if params[:query].blank?
      redirect_to(root_path) && return
    else
      @equipment_model_results =
        EquipmentModel.active.catalog_search(params[:query])
      @category_results = Category.catalog_search(params[:query])
      @equipment_item_results =
        EquipmentItem.catalog_search(params[:query])
      prepare_catalog_index_vars(@equipment_model_results)
      render('search_results') && return
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
  # it takes either :add_item or :remove_item as an action variable and adds
  # or removes the equipment_model set from params{} in the before_action.
  # Finally, it renders the root page and runs the javascript to update the
  # cart (or displays the appropriate errors)
  def change_cart(action, item, quantity = nil)
    cart.send(action, item, quantity)
    @errors = cart.validate_all
    flash[:error] = @errors.join("\n")
    flash[:notice] = 'Cart updated.'

    respond_to do |format|
      format.html { redirect_to root_path }
      format.js do
        # this isn't necessary for EM show page updates but not sure how to
        # check for catalog views since it's always in the catalog controller
        prepare_catalog_index_vars([item])
        @item = item
        render template: 'cart_js/update_cart'
      end
    end
  end

  def prepare_pagination
    array = []
    array << params[:items_per_page].to_i
    array << session[:items_per_page].to_i
    array << @app_configs.default_per_cat_page
    array << 10
    items_per_page = array.reject { |a| a.blank? || a.zero? }.first
    # assign items per page to the passed params, the default or 10
    # depending on if they exist or not
    @per_page_opts = [10, 20, 25, 30, 50].unshift(items_per_page).uniq
    session[:items_per_page] = items_per_page
  end
end
