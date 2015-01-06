# rubocop:disable ClassLength
class ReportsController < ApplicationController
  authorize_resource class: false
  DetailInfo = Struct.new(:name, :table, :params)

  def index # rubocop:disable MethodLength, AbcSize
    @res_stat_sets = []
    @start_date = start_date
    @end_date = end_date

    # filter reservations by date
    reservations = Reservation.starts_on_days(@start_date, @end_date)
                .includes(:equipment_model)
    eq_models = Report.build_new("Equipment Models", :equipment_model_id,
                                :for_model_report_path, reservations)
    categories = Report.build_new("Categories", :category_id, nil, 
                                  reservations)
    table_hash = {}
    table_hash[:rows] = eq_models.rows
    table_hash[:col_names] = eq_models.columns.collect { |c| c.name }
    cat_hash = {}
    cat_hash[:rows] = categories.rows
    cat_hash[:col_names] = categories.columns.collect { |c| c.name }
    @data_tables = {}
    @data_tables[eq_models.name] = table_hash
    @data_tables["Categories"] = cat_hash

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

  # sub report for a particular model
  def for_model
    @equipment_model = EquipmentModel.find(params[:id])
    @start_date = start_date
    @end_date = end_date
    binding.pry
  end

  # should probably 
  def for_category
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
