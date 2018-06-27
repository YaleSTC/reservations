# frozen_string_literal: true

# rubocop:disable ClassLength
class EquipmentModelsController < ApplicationController
  layout 'application_with_sidebar', only: :show
  load_and_authorize_resource
  decorates_assigned :equipment_model
  skip_before_action :authenticate_user!, only: %i[show index],
                                          unless: :guests_disabled?
  before_action :set_equipment_model,
                only: %i[show edit update destroy deactivate]
  before_action :set_category_if_possible, only: %i[index new]

  include ActivationHelper
  include CsvExport
  include Calendarable

  # --------- before filter methods --------- #
  def set_equipment_model
    @equipment_model = EquipmentModel.find(params[:id])
  end

  def set_category_if_possible
    @category = Category.find(params[:category_id]) if params[:category_id]
  end
  # --------- end before filter methods --------- #

  def index
    base = @category ? @category.equipment_models : EquipmentModel.all
    if params[:show_deleted]
      @equipment_models = base.includes(:reservations)
    else
      @equipment_models = base.includes(:reservations).active
    end

    respond_to do |format|
      format.html
      format.zip { download_equipment_data }
    end
  end

  def show # rubocop:disable AbcSize, MethodLength
    calculate_availability
    relevant_reservations =
      Reservation.for_eq_model(@equipment_model.id).active
    @associated_equipment_models =
      @equipment_model.associated_equipment_models.sample(6)

    calendar_length = 1.month

    @reservation_data = relevant_reservations.collect do |r|
      end_date = if r.overdue
                   Time.zone.today + calendar_length
                 else
                   r.due_date
                 end
      { start: r.start_date, end: end_date }
      # the above code mimics the current available? setup to show overdue
      # equipment as permanently 'out'.
    end

    @blackouts = Blackout.active.collect do |b|
      { start: b.start_date, end: b.end_date }
    end

    @date = Time.zone.today
    @date_max = @date + calendar_length - 1.week
    @max = @equipment_model.equipment_items.active.count

    @restricted = @equipment_model.model_restricted?(cart.reserver_id)

    # For pending reservations table
    @pending =
      relevant_reservations.reserved
                           .overlaps_with_date_range(Time.zone.today,
                                                     Time.zone.today + 8.days)
    # Future reservations using Query object
    @future = @pending.future
  end

  def new
    @equipment_model = EquipmentModel.new(category: @category)
  end

  def create
    @equipment_model = EquipmentModel.new(equipment_model_params)
    if @equipment_model.save
      flash[:notice] = 'Successfully created equipment model.'
      redirect_to @equipment_model
    else
      flash[:error] = 'Please review the errors below. '
      render action: 'new'
    end
  end

  def edit; end

  def update
    delete_files

    eq_params = equipment_model_params
    # correct for file type
    eq_params[:documentation] = fix_content_type(eq_params[:documentation])

    if @equipment_model.update_attributes(eq_params)
      # hard-delete any deleted checkin/checkout procedures
      delete_procedures(params, 'checkout')
      delete_procedures(params, 'checkin')
      flash[:notice] = 'Successfully updated equipment model.'
      redirect_to @equipment_model
    else
      render action: 'edit'
    end
  end

  def deactivate
    if params[:deactivation_cancelled]
      flash[:notice] = 'Deactivation cancelled.'
      redirect_to @equipment_model
    elsif params[:deactivation_confirmed]
      Reservation.for_eq_model(@equipment_model.id).finalized.each do |r|
        r.archive(current_user, 'The equipment model was deactivated.')
         .save(validate: false)
      end
      super
    else
      flash[:error] = 'Oops, something went wrong.'
      redirect_to @equipment_model
    end
  end

  private

  # function to check for deleted checkin/checkout procedures and hard-delete
  # them after equipment model update
  def delete_procedures(params, phase)
    # phase needs to be equal to either "checkout" or "checkin"
    phase_params = params[:equipment_model][:"#{phase}_procedures_attributes"]
    return if phase_params.nil?
    phase_params.each do |k, v|
      if v['id'] && v['_destroy'] != 'false'
        @equipment_model.send(:"#{phase}_procedures")[k.to_i].destroy(:force)
      end
    end
  end

  def delete_files
    # for a given filetype affected by param value, the file in question is
    # saved in path contained value
    types = { 'clear_documentation' => :documentation,
              'clear_photo' => :photo }

    # only keep pairs that occur as keys with non-nil values in params
    types.select! { |k, v| params.keys.member?(k) && !v.nil? }
    types.each { |_k, attr| params[:equipment_model][attr] = nil }
  end

  def equipment_model_params
    # manually add on the procedure elements from params since they
    # don't have fixed hash keys (check to see if they exist first
    # to resolve test failures)
    params.require(:equipment_model)
          .permit(:name, :category_id, :category, :description, :late_fee,
                  :replacement_fee, :max_per_user, :deleted_at, :photo,
                  :documentation, :max_renewal_times, :max_renewal_length,
                  :renewal_days_before_due, :late_fee_max,
                  { associated_equipment_model_ids: [] }, :requirement_ids,
                  :requirements, :max_checkout_length,
                  checkin_procedures_attributes: {},
                  checkout_procedures_attributes: {})
  end

  # from https://gist.github.com/cnk/4453c6e81837e8d38b7e
  def fix_content_type(filedata)
    return nil if filedata.blank?
    # see what the unix file command thinks this is
    if filedata.content_type == 'application/octect-stream'
      filedata.content_type = type_from_file_command(filedata.path)
    end
    filedata
  end

  def type_from_file_command(file)
    Paperclip::FileCommandContentTypeDetector.new(file).detect
  end

  def generate_calendar_reservations
    # we need uniq because it otherwise includes overdue reservations in the
    # date range twice
    (Reservation.for_eq_model(@equipment_model.id).includes(:equipment_item)
      .overlaps_with_date_range(@start_date, @end_date).finalized
      .where.not(status: 'archived') + \
      Reservation.for_eq_model(@equipment_model.id).includes(:equipment_item)
        .overdue).uniq
  end

  def generate_calendar_resource
    @equipment_model
  end

  def calendar_name_method
    :reserver
  end

  def calculate_availability
    # get start and end dates
    @start_date = Time.zone.today.beginning_of_week(:sunday)
    @end_date = (Time.zone.today + 1.month).end_of_week(:sunday)

    max_avail = @equipment_model.equipment_items.active.count

    @avail_data = []
    (@start_date..@end_date).map do |date|
      availability = @equipment_model.num_available_on(date)
      # set up colors
      if date < Time.zone.today
        color = '#888'
      elsif availability.zero?
        color = '#d9534f'
      elsif availability == max_avail
        color = '#5cb85c'
      elsif availability > [0.25 * max_avail, 1].max
        color = '#94d194'
      elsif availability <= [0.25 * max_avail, 1].max
        color = '#f0ad4e'
      end
      @avail_data << { title: availability.to_s, start: date, end: date,
                       allDay: true, color: color }
    end
  end
end
