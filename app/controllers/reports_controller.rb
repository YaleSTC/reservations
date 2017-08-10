# frozen_string_literal: true

class ReportsController < ApplicationController
  authorize_resource class: false
  MODEL_COLUMNS = [['Total', :all, :count],
                   ['Reserved', :reserved, :count],
                   ['Checked Out', :checked_out, :count],
                   ['Overdue', :overdue, :count],
                   ['Returned On Time', :returned_on_time, :count],
                   ['Returned Overdue', :returned_overdue, :count],
                   ['Avg Planned Duration', :all, :duration],
                   ['Avg Time Checked Out', :all, :time_checked_out]].freeze
  RES_COLUMNS = [['Reserver', :all, :name, :reserver],
                 ['Equipment Model', :all, :name, :equipment_model],
                 ['Equipment Item', :all, :name, :equipment_item],
                 ['Status', :all, :display, :status],
                 ['Start Date', :all, :display, :start_date],
                 ['Checked Out', :all, :display, :checked_out],
                 ['Due Date', :all, :display, :due_date],
                 ['Checked In', :all, :display, :checked_in]].freeze

  before_action :set_dates, only: %i[index subreport]

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
    if params[:report] && params[:report][:start_date] &&
       params[:report][:end_date]
      @start_date = params[:report][:start_date].to_date
      @end_date = params[:report][:end_date].to_date
      session[:report_start_date] = @start_date
      session[:report_end_date] = @end_date
    end

    respond_to do |format|
      format.js { render inline: 'location.reload();' }
    end
  end

  def subreport
    resource = ClassFromString.reports!(params[:class])
    id_symbol = id_symbol_for(resource)

    @object = resource.find(params[:id])

    id = if resource == Category
           EquipmentModel.where(category_id: params[:id]).collect(&:id)
         else
           sanitize_sql(params[:id])
         end

    # also NOT a SQL-injection -- id_symbol is built by ClassFromString,
    # which only allows certain classes, and id is sanitized above
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

  def id_symbol_for(resource)
    if resource == User
      :reserver_id
    elsif resource == Category
      :equipment_model_id
    else
      (resource.to_s.downcase + '_id').to_sym
    end
  end

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
