# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class EquipmentItemsController < ApplicationController
  load_and_authorize_resource
  decorates_assigned :equipment_item
  before_action :set_current_equipment_item,
                only: %i[show edit update destroy deactivate
                         activate]
  before_action :set_equipment_model_if_possible, only: %i[index new]

  include ActivationHelper
  include CsvExport
  include Calendarable

  # ---------- before filter methods ---------- #

  def set_current_equipment_item
    @equipment_item = EquipmentItem.find(params[:id])
  end

  def set_equipment_model_if_possible
    return unless params[:equipment_model_id]
    @equipment_model = EquipmentModel.find(params[:equipment_model_id])
  end

  # ---------- end before filter methods ---------- #

  def index
    method = params[:show_deleted] ? :all : :active
    if @equipment_model
      @equipment_items = @equipment_model.equipment_items.send(method)
    else
      @equipment_items = EquipmentItem.send(method)
    end
    respond_to do |format|
      format.html
      format.zip { download_equipment_data }
    end
  end

  def show
    prepare_calendar_vars
  end

  def new
    @equipment_item = EquipmentItem.new(equipment_model: @equipment_model)
  end

  def create
    @equipment_item = EquipmentItem.new(equipment_item_params)
    @equipment_item.notes = "#### Created at #{Time.zone.now.to_s(:long)} "\
      "by #{current_user.md_link}."
    if @equipment_item.save
      flash[:notice] = 'Successfully created equipment item. '\
        "#{@equipment_item.serial}"
      redirect_to @equipment_item.equipment_model
    else
      render action: 'new'
    end
  end

  def edit; end

  def update
    p = equipment_item_params
    if p[:deleted_at].blank?
      # Delete deactivation reason when "Disabled?" is toggled
      p[:deactivation_reason] = ''
    end
    @equipment_item.update(current_user, p)
    if @equipment_item.save
      flash[:notice] = 'Successfully updated equipment item.'
      redirect_to @equipment_item
    else
      render action: 'edit'
    end
  end

  # extend ApplicationController method; calls destroy twice due to presence of
  # model method
  def deactivate
    if params[:deactivation_reason] && !params[:deactivation_cancelled]
      @equipment_item.deactivate(user: current_user,
                                 reason: params[:deactivation_reason])
      # archive current reservation if any
      if @equipment_item.current_reservation
        @equipment_item.current_reservation.archive(
          current_user,
          'The equipment item was deactivated for the following reason: '\
          "**#{params[:deactivation_reason]}**"
        ).save(validate: false)
      end
      super
    elsif params[:deactivation_cancelled]
      flash[:notice] = 'Deactivation cancelled.'
      redirect_to @equipment_item.equipment_model
    else
      flash[:error] = 'Please enter a deactivation reason.'
      redirect_to @equipment_item.equipment_model
    end
  end

  # activate extends controller method from ApplicationController
  def activate
    super
    new_notes = "#### Reactivated at #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}\n\n" + @equipment_item.notes
    @equipment_item.update_attributes(deactivation_reason: nil,
                                      notes: new_notes)
  end

  private

  def equipment_item_params
    params.require(:equipment_item)
          .permit(:name, :serial, :deleted_at, :equipment_model_id,
                  :deactivation_reason, :notes)
  end

  def generate_calendar_reservations
    # we need uniq because it otherwise includes overdue reservations in the
    # date range twice
    (@equipment_item.reservations.includes(:equipment_item)
      .overlaps_with_date_range(@start_date, @end_date).finalized
      .where.not(status: 'archived') + \
      @equipment_item.reservations.includes(:equipment_item).overdue).uniq
  end

  def generate_calendar_resource
    @equipment_item
  end

  def calendar_name_method
    :reserver
  end
end
