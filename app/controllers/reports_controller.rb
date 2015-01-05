# rubocop:disable ClassLength
class ReportsController < ApplicationController
  authorize_resource class: false
  # relations to build data columns ()
  ColumnBuilder = Struct.new(:name, :relation, :params)
  # output structure (name = string, data = array, link_path = link for first
  # element in row)
  StatRow = Struct.new(:name, :data, :link_path)
  # info for a reservation set (building rows of data).
  # Pass in the array of ids and what type of ids the row of reservation is
  # collected by.  The link path is passed to the stat row
  RowBuilder = Struct.new(:name, :id_type, :ids, :link_path)
  # stores the info for building columns (for the details on the reservations)
  DetailInfo = Struct.new(:name, :table, :params)
  SCOPES = { :"Total" => nil, :"Reserved" => :reserved,
               :"Checked Out" => :checked_out, :"Overdue" => :overdue,
               :"Returned On Time" => :returned_on_time,
               :"Returned Overdue" => :returned_overdue,
               :"Missed" => :missed }


  def average2 arr
    if arr.size == 0
      'N/A'
    else
      (arr.inject { |r, e| r + e }.to_f / arr.size).round(2)
    end
  end
    
  def avg_duration res_set
    average2(res_set.collect { |r| r.duration })
  end

  def avg_time_out res_set
    average2(res_set.collect { |r| r.time_checked_out })
  end

  class Reservation::ActiveRecord_Relation
    include Rails.application.routes.url_helpers
    
    def reserver_row_builders
      reservers = self.collect(&:reserver).uniq
      reservers.collect do |user|
        RowBuilder.new(user.name, :reserver_id, [user.id],
                       user_path(id: user.id))
      end
      reservers
    end

    def equipment_row_builders
      eq_model_info = []
      cat_em_ids = {}
      em_ids = self.collect(&:equipment_model_id).uniq
      eq_models = EquipmentModel.includes(:category).find(em_ids)
      eq_models.each do |em|
        eq_model_info << RowBuilder.new(em.name, :equipment_model_id, [em.id],
                                        for_model_report_path(id: em.id))
        if cat_em_ids[em.category.id]
          cat_em_ids[em.category.id] << em.id
        else
          cat_em_ids[em.category.id] = [em.id]
        end
      end
      categories = Category.find(cat_em_ids.keys)
      category_info = categories.collect do |cat|
        RowBuilder.new(cat.name, :equipment_model_id, cat_em_ids[cat.id],
                       for_model_set_reports_path(ids: cat_em_ids[cat.id]))
      end
      return eq_model_info, category_info
    end

    def build_relations_set
      # reservation relations for each of the scopes
      def_options = { stat_type: :count }
      res_rels = []
      SCOPES.each do |key, value|
        rel = value ? self.send(value) : self
        res_rels << ColumnBuilder.new(key.to_s, rel, def_options)
      end
      res_rels
    end

  end
 
  # The idea I had behind reports was to be able to have relatively flexible
  # report building capabilities without a lot of queries
  #
  # build_table
  # builds a table in rows where each row is a set of reservations and the
  # relation filters the data again by column - it's useful for subgrouping
  # the reservations, and params lets you alter what kind of data you're
  # looking for
  #
  # assoc_details and collect_res_details take the set of
  # reservations, and for each reservation collect details from associated
  # tables, and the reservation table
  #
  # ColumnBuilder should really be renamed ColumnBuilder. It has a few fields:
  # Title ; the text displayed at the head of the data column
  # Relation ; the ActiveRecord::Relation instance of the reservations
  #   that the column cares about
  # Options ; a cheap trick to get in multiple arguments at the end here.
  #   I want to rearchitect this to be stat_type instead. The logic will go,
  #   'duration, time_out, count' are special keywords
  #   any other word will assume it is counting the field
  #
  #
  # Properties of a table; how best to organize them?
  # (Full) Set of Reservations
  #   - Criteria for filtering; eg category, EM, user, EO, etc.
  # Column headers
  #   - for each column, how to filter the reservations (relation)
  #   - for each row, how to display the data
  # Row headers
  #   - what are the rows (id_type)
  #   - for each row, what object is it (this is a full table metadata)
  # So..
  #
  # Struct TableBuilder
  #   - Name
  #   - AR relation for 'all reservations'
  #   - RowObject type
  #   - Array of ColRelationDisplays
  #   - Array of RowObjects
  #
  # Struct ColRelationDisplay (name subject to change)
  #   - Name
  #   - AR relation
  #   - Display type
  #
  # Struct RowObject
  #   - Name
  #   - Link path
  #   - Object ID
  #
  # Building the table
  # 1x query to get the TableBuilder AR
  # n-columns x queries to get ARs for each column
  # that's it; when building rows use Array.select to match the ids
  #
  #  Struct Table
  #   - Array of column headings (strings)
  #   - Array of Rows
  #  Struct Row
  #   - Name
  #   - Link path (these can be copied from Row Object)
  #   - Array of data (strings or ints)
  #

  def index # rubocop:disable MethodLength, AbcSize
    @res_stat_sets = []
    @start_date = start_date
    @end_date = end_date

    # filter reservations by date
    reservations = Reservation.starts_on_days(@start_date, @end_date)
                .includes(:equipment_model)

    # build ColumnBuilders array; these are the columns of the data table
    columns = reservations.build_relations_set
    columns << ColumnBuilder.new('User Count', reservations,
                                stat_type: :count, 
                                secondary_id: :reserver_id)

    # Get RowBuilder array data from the reservation sets; these are 
    # basically the rows for each data table 
    equipment_row_builders = reservations.equipment_row_builders
    eq_models = equipment_row_builders[0]
    categories = equipment_row_builders[1]
    #reserver_info = reservations.user_row_builders

    # sets of reservations are passed in by name then models associated
    all_models = [RowBuilder.new('All Models', :equipment_model_id)]

    table_types = { total: all_models, #users: reserver_info,
                  categories: categories, equipment_models: eq_models }
    @data_tables = {}
    table_types.each do |name, rows|
      @data_tables[name] = build_table(rows, columns)
    end

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
    @data_tables = models_subreport([params[:id]], @start_date, @end_date,
                                    [@equipment_model])
  end

  # should probably merge with for_model
  def for_model_set
    @equipment_models = EquipmentModel.find(params[:ids])
    @start_date = start_date
    @end_date = end_date
    @data_tables = models_subreport(params[:ids], @start_date, @end_date,
                                    @equipment_models)
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

  # forms a set of relations with the default settings, or a set of relations
  # with the same options
  
  # build the canned report for a model/set of models
  # rubocop:disable MultilineOperationIndentation, MethodLength, AbcSize
  def models_subreport(ids, start_date, end_date, eq_models)
    res_set = Reservation.includes(:equipment_model, :equipment_object)
                         .starts_on_days(start_date, end_date)
                         .where(equipment_model_id: ids)
    res_rels = build_relations_set(res_set)
    res_rels << ColumnBuilder.new('Avg Planned Duration', res_set,
                                stat_type: :duration)
    res_rels << ColumnBuilder.new('Avg Duration Checked Out', res_set,
                                stat_type: :time_checked_out)

    em_info = eq_models.collect do |em|
      em_link = ids.size > 1 ? for_model_report_path(id: em.id) : nil
      RowBuilder.new(em.name, :equipment_model_id, [em.id], em_link)
    end
    em_stats = build_table(em_info, res_rels)

    # collect data for users table
    reserver_ids = res_set.collect(&:reserver_id).uniq
    users = User.find(reserver_ids)
    user_info = users.collect do |user|
      RowBuilder.new(user.name, :reserver_id, [user.id],
                     user_path(id: user.id))
    end
    user_stats = build_table(user_info, res_rels)

    # collect data by equipment object
    eq_objects = EquipmentObject.where(equipment_model_id: ids)
    obj_info = eq_objects.collect do |obj|
      RowBuilder.new(obj.name, :equipment_object_id, [obj.id])
    end
    obj_stats = build_table(obj_info, res_rels)

    det_structs = [DetailInfo.new('Reserver', users,
                                  secondary_id: :reserver_id,
                                  info_type: :name),
                   DetailInfo.new('Equipment Model', eq_models,
                                  secondary_id: :equipment_model_id,
                                  info_type: :name),
                   DetailInfo.new('Equipment Object', eq_objects,
                                  secondary_id: :equipment_object_id,
                                  info_type: :name)]

    fields = { status: nil, start_date: { call: :to_date },
               due_date: { call: :to_date }, checked_out: { call: :to_date },
               checked_in: { call: :to_date } }
    res_stats = collect_res_info(res_set, det_structs, fields)

    # model_tables = { equipment_models: em_stats, equipment_objects: obj_stats,
    #                  users: user_stats }
    model_tables = { equipment_models: em_stats, equipment_objects: obj_stats,
                     users: user_stats, reservations: res_stats }
    model_tables
  end
  # rubocop:enable MultilineOperationIndentation, MethodLength, AbcSize

 
  def build_data(res_set, params)
    case params[:stat_type]
    when :count
      return res_set.count unless params[:secondary_id]
      ids = res_set.collect do |res|
        res.send(params[:secondary_id])
      end
      return ids.uniq.count
    when :duration
      return avg_duration res_set
    when :time_checked_out
      return avg_time_out res_set
    end
  end

  def build_table(info_struct, res_rels) # rubocop:disable all
    # iterate by row
    # takes 2 args; an array of ResInfo structs 
    # and an array of Resrelations
    # returns a hash of rows and column names?
    #
    # the column names are the relation names, eg 'upcoming' etc.
    # for each item in the info struct (eg each equipment model)
    #   make a new stat row object with the model type, link path and empty data set
    #   for each type of reservation filter
    #     select the reservations that match the criteria res.send(info.id_type) that are in res_rels
    #     then update the data of the stat_row object
    #
    #     For count; count all the unique objects in res_set
    #       If there's a secondary id, count all the unique res.send(secondary_id)
    #     For duration; 
    #
    # 
    stat_set = {}
    stat_set[:rows] = []
    stat_set[:col_names] = res_rels.collect { |res| res[:name] }
    info_struct.each do |info|
      stat_row = StatRow.new(info.name, [], info.link_path)
      res_rels.each do |rel_struct|
        rel = rel_struct[:relation]
        params = rel_struct[:params]
        # select the reservations whose id of :id_type that are in the array
        # of ids e.g. equipment_model_id is a member of [1,2,3]
        if info.ids
          res_set = rel.select do |res|
            info.ids.include?(res.send(info.id_type))
          end
        else
          res_set = rel.all
        end
        stat_row.data << build_data(res_set, params)
      end
      stat_set[:rows] << stat_row
    end
    stat_set
  end

  # stupid default scope for users, messes with includes, so it ends up doing
  # many more queries than necessary thus this function was written for users
  # pulls details from associated tables and assigns them per reservation
  # hard to do as a join because you need to also run object functions on
  # them. Still probably should be rewritten
  def assoc_details(tables, res_set)
    # pass in the table structures, which contain the name, table and parameters
    col_hash = {}
    tables.each do |table_struct| # collects the info once per id
      table = table_struct.table
      params = table_struct.params
      table_hash = {}
      table.each { |item| table_hash[item.id] = item.send(params[:info_type]) }
      stat_arr = []
      res_set.each do |res|
        stat_arr << table_hash[res.send(params[:secondary_id])]
      end
      col_hash[table_struct.name] = stat_arr
    end
    col_hash
  end

  # for the collection of data for each of the reservations in the
  # reservation set
  def collect_res_info(res_set, det_structs = nil, fields = {})
    # collect data present on other tables
    det_columns = det_structs ? assoc_details(det_structs, res_set) : {}
    # collect data for fields in the reservation table
    fields.each do |f, option|
      det_columns[f] = res_set.collect do |res|
        if option && option[:call]
          res.send(f) ? res.send(f).send(option[:call]) : 'N/A'
        else
          res.send(f)
        end
      end
    end
    # format the data into a reservation stat set
    res_stats = {}
    res_stats[:col_names] = det_columns.keys.collect { |key| key.to_s.titleize }
    res_stats[:rows] = res_set.collect { |res| StatRow.new(res.id, []) }
    det_columns.each do |_key, col|
      col.each_index do |ind|
        res_stats[:rows][ind].data << col[ind]
      end
    end
    res_stats
  end
end
