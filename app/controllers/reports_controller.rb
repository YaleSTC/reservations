# rubocop:disable ClassLength
class ReportsController < ApplicationController
  authorize_resource class: false
  DetailInfo = Struct.new(:name, :table, :params)
  MODEL_COLUMNS = [ ['Total', :all, :count],
                      ['Reserved', :reserved, :count],
                      ['Checked Out', :checked_out, :count],
                      ['Overdue', :overdue, :count],
                      ['Returned On Time', :returned_on_time, :count],
                      ['Returned Overdue', :returned_overdue, :count],
                      ['Avg Planned Duration', :all, :duration],
                      ['Time Checked Out', :all, :time_checked_out]
  ]

  def index # rubocop:disable MethodLength, AbcSize
    @res_stat_sets = []
    @start_date = start_date
    @end_date = end_date

    # filter reservations by date
    reservations = Reservation.starts_on_days(@start_date, @end_date)
                .includes(:equipment_model)
    eq_models = Report.build_new("Equipment Models", :equipment_model_id,
                                :for_model_report_path, reservations)
    categories = Report.build_new("Categories", :category_id, 
                                :for_category_report_path,  reservations)
    @data_tables = {}
    @data_tables[:equipment_models] = eq_models
    @data_tables[:categories] = categories

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
      format.js { render template: 'reports/report_dates_reload' }
      # guys i really don't like how this is rendering a template for js, but
      # :action doesn't work at all
      format.html { render partial: 'reports/report_dates' } # delete this
      # line? replace with redirect_to root_path ? otherwise it's not doing
      # any harm
    end
    # @end_date = (Date.strptime(params[:report][:end_date],'%m/%d/%Y'))
  end

  # needs to be expanded later
  def generate
    redirect_to request.referrer
  end

  def for_model
    @equipment_model = EquipmentModel.find(params[:id])
    @start_date = start_date
    @end_date = end_date
    reservations = Reservation.starts_on_days(@start_date, @end_date)
                .where(equipment_model: @equipment_model)
                .includes(:equipment_model)
    @data_tables = build_subreports reservations
       
  end

  def for_category
    @category = Category.find(params[:id])
    @start_date = start_date
    @end_date = end_date
    ids = EquipmentModel.where(category_id: params[:id]).collect(&:id)
    reservations = Reservation.starts_on_days(@start_date, @end_date)
                .where(equipment_model_id: ids)
                .includes(:equipment_model)
    @data_tables = build_subreports reservations

  end

  def build_subreports reservations
    @data_tables = {}
    @data_tables[:equipment_models] = Report.build_new('Equipment Model',
                                                       :equipment_model_id,
                                                       :equipment_model_path,
                                                       reservations, 
                                                       MODEL_COLUMNS)
    @data_tables[:equipment_objects] = Report.build_new('',
                                                 :equipment_object_id,
                                                 :equipment_object_path,
                                                 reservations,
                                                 MODEL_COLUMNS)
    @data_tables[:users] = Report.build_new('Users',
                                            :reserver_id,
                                            :user_path,
                                            reservations,
                                            MODEL_COLUMNS)
    @data_tables
  end


  private
 
  def start_date
    session[:report_start_date].present? ?
      session[:report_start_date] : Date.current - 1.year
  end

  def end_date
    session[:report_end_date].present? ?
      session[:report_end_date] : Date.current
  end

end
