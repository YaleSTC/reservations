class ReportsController < ApplicationController
  authorize_resource class: false
  MODEL_COLUMNS = [['Total', :all, :count],
                   ['Reserved', :reserved, :count],
                   ['Checked Out', :checked_out, :count],
                   ['Overdue', :overdue, :count],
                   ['Returned On Time', :returned_on_time, :count],
                   ['Returned Overdue', :returned_overdue, :count],
                   ['Avg Planned Duration', :all, :duration],
                   ['Avg Time Checked Out', :all, :time_checked_out]
                  ]
  RES_COLUMNS = [['Reserver', :all, :name, :reserver],
                 ['Equipment Model', :all, :name, :equipment_model],
                 ['Equipment Item', :all, :name, :equipment_item],
                 ['Status', :all, :display, :status],
                 ['Start Date', :all, :display, :start_date],
                 ['Checked Out', :all, :display, :checked_out],
                 ['Due Date', :all, :display, :due_date],
                 ['Checked In', :all, :display, :checked_in]]

  before_action :set_dates, only: [:index, :subreport]

  def set_dates
    @start_date = start_date
    @end_date = end_date
  end

  def index
    # filter reservations by date
    reservations = Reservation.starts_on_days(@start_date, @end_date)
    tables = {}
    tables[:equipment_models] = Report.build_new(:equipment_model_id,
                                                 reservations)
    tables[:categories] = Report.build_new(:category_id, reservations)
    @data_tables = tables

    respond_to do |format|
      format.html
      format.csv { render layout: false }
    end
  end

  # get dates from datepicker
  def update_dates
    @start_date = params[:report][:start_date].to_date
    @end_date = params[:report][:end_date].to_date
    session[:report_start_date] = @start_date
    session[:report_end_date] = @end_date

    respond_to do |format|
      format.js { render inline 'location.reload();' }
    end
  end

  def subreport
    id_symbol = (params[:class] + '_id').to_sym
    resource = params[:class].camelize.constantize

    id_symbol = :reserver_id if resource == User

    id = params[:id]
    @object = resource.find params[:id]

    if resource == Category
      id = EquipmentModel.where(category_id: id).collect(&:id)
      id_symbol = :equipment_model_id
    end

    reservations = Reservation.starts_on_days(@start_date, @end_date)
                   .where(id_symbol => id)

    @data_tables = build_subreports reservations

    respond_to do |format|
      format.html
      format.csv { render layout: false }
    end
  end

  def build_subreports(reservations)
    tables = {}
    tables[:equipment_models] = Report.build_new(:equipment_model_id,
                                                 reservations, MODEL_COLUMNS)
    tables[:equipment_items] = Report.build_new(:equipment_item_id,
                                                reservations, MODEL_COLUMNS)
    tables[:users] = Report.build_new(:reserver_id, reservations, MODEL_COLUMNS)
    tables[:reservations] = Report.build_new(:id, reservations, RES_COLUMNS)
    tables
  end

  private

  def start_date
    if session[:report_start_date].present?
      session[:report_start_date]
    else
      Time.zone.today - 1.year
    end
  end

  def end_date
    if session[:report_end_date].present?
      session[:report_end_date]
    else
      Time.zone.today
    end
  end
end
