# frozen_string_literal: true

class CategoriesController < ApplicationController
  load_and_authorize_resource
  decorates_assigned :category
  before_action :set_current_category,
                only: %i[show edit update destroy deactivate]

  include ActivationHelper
  include CsvExport
  include Calendarable

  # --------- before filter methods -------- #
  def set_current_category
    @category = Category.find(params[:id])
  end
  # --------- end before filter methods -------- #

  def index
    @categories = if params[:show_deleted]
                    Category.all
                  else
                    Category.active
                  end
    respond_to do |format|
      format.html
      format.zip { download_equipment_data }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.zip do
        models = @category.equipment_models
        items = EquipmentItem.where(equipment_model_id: models.all.map(&:id))
        download_equipment_data(cats: [@category], models: models, items: items)
      end
    end
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = 'Successfully created category.'
      redirect_to @category
    else
      flash[:error] = 'Oops! Something went wrong with creating the category.'
      render action: 'new'
    end
  end

  def edit; end

  def update
    if @category.update_attributes(category_params)
      flash[:notice] = 'Successfully updated category.'
      redirect_to @category
    else
      render action: 'edit'
    end
  end

  def deactivate
    if params[:deactivation_cancelled]
      flash[:notice] = 'Deactivation cancelled.'
      redirect_to @category
    elsif params[:deactivation_confirmed]
      @category.equipment_models.each do |em|
        Reservation.for_eq_model(em.id).finalized.each do |r|
          r.archive(current_user, 'The category was deactivated.')
           .save(validate: false)
        end
      end
      super
    else
      flash[:error] = 'Oops, something went wrong.'
      redirect_to @category
    end
  end

  private

  def category_params
    params.require(:category)
          .permit(:name, :max_per_user, :max_checkout_length, :deleted_at,
                  :max_renewal_times, :max_renewal_length, :sort_order,
                  :renewal_days_before_due)
  end

  def generate_calendar_reservations
    # we need uniq because it otherwise includes overdue reservations in the
    # date range twice
    (Reservation.for_cat(@category.id).finalized.where.not(status: 'archived')
      .includes(:equipment_item, :equipment_model)
      .overlaps_with_date_range(@start_date, @end_date) + \
      Reservation.for_cat(@category.id)
        .includes(:equipment_item, :equipment_model).overdue).uniq
  end

  def generate_calendar_resource
    @category
  end

  def calendar_name_method
    :equipment_model
  end
end
