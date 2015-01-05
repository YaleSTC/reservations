# rubocop:disable ClassLength
class ReportsController < ApplicationController
  authorize_resource class: false
  # relations to build data columns ()
  ResRelation = Struct.new(:name, :relation, :params)
  # output structure (name = string, data = array, link_path = link for first
  # element in row)
  StatRow = Struct.new(:name, :data, :link_path)
  # info for a reservation set (building rows of data).
  # Pass in the array of ids and what type of ids the row of reservation is
  # collected by.  The link path is passed to the stat row
  ResSetInfo = Struct.new(:name, :id_type, :ids, :link_path)
  # stores the info for building columns (for the details on the reservations)
  DetailInfo = Struct.new(:name, :table, :params)

  class Array 
    def average2
      if size == 0
        'N/A'
      else
        (self.inject { |r, e| r + e }.to_f / size).round(2)
      end
    end
  end

  class Reservation::ActiveRecord_Relation
    def avg_duration
      self.collect { |r| r.duration }.average2
    end
    def avg_time_out
      self.collect { |r| r.time_checked_out }.average2
    end

    def user_info
      reservers = self.collect(&:reserver).uniq
      reservers.collect do |user|
        ResSetInfo.new(user.name, :reserver_id, [user.id],
                       user_path(id: user.id))
      end
    end

    def equipment_info
      eq_model_info = []
      cat_em_ids = {}
      em_ids = self.collect(&:equipment_model_id).uniq
      eq_models = EquipmentModel.includes(:category).find(em_ids)
      eq_models.each do |em|
        eq_model_info << ResSetInfo.new(em.name, :equipment_model_id, [em.id],
                                        for_model_report_path(id: em.id))
        if cat_em_ids[em.category.id]
          cat_em_ids[em.category.id] << em.id
        else
          cat_em_ids[em.category.id] = [em.id]
        end
      end
      categories = Category.find(cat_em_ids.keys)
      category_info = categories.collect do |cat|
        ResSetInfo.new(cat.name, :equipment_model_id, cat_em_ids[cat.id],
                       for_model_set_reports_path(ids: cat_em_ids[cat.id]))
      end
      return eq_model_info, category_info
    end


  end
 
  def get_duration(res, date_hash)
    start = res.send(date_hash[:start])
    finish = res.send(date_hash[:finish])
    start ||= date_hash[:catch1]
    finish ||= date_hash[:catch2]
    if start && finish
      return finish.to_date - start.to_date
    else
      return nil
    end
  end


  # The idea I had behind reports was to be able to have relatively flexible
  # report building capabilities without a lot of queries
  #
  # collect_stat_set
  # builds a table in rows where each row is a set of reservations and the
  # relation filters the data again by column - it's useful for subgrouping
  # the reservations, and params lets you alter what kind of data you're
  # looking for
  #
  # assoc_details and collect_res_details take the set of
  # reservations, and for each reservation collect details from associated
  # tables, and the reservation table

  # INDEX
  #   get all reservations that start in the given date range
  #   build an array of ResRelation objects with the default relations hash
  #   add to this array a User Count ResRelation object whose params are a thing
  #
  #   Now get all the equipment models in the set
  #   Make an array of ResSetInfo objects (eq_model_info)
  #   Make a hash of category_em_ids
  #   For every model in the set, add a new ResSetInfo object
  #   For every model in the set, add its ID to the category hash
  #     key: category ID
  #     value: model ID
  #   Get all the categories and do the same thing, making an array 
  #   of ResSetInfo structs
  #   
  #

  def index # rubocop:disable MethodLength, AbcSize
    @res_stat_sets = []
    @start_date = start_date
    @end_date = end_date

    full_set = Reservation.starts_on_days(@start_date, @end_date)
                .includes(:equipment_model)
    res_rels = build_relations_set(full_set)
    res_rels << ResRelation.new('User Count', full_set,
                                id_type: :equipment_model_id,
                                stat_type: :count, 
                                secondary_id: :reserver_id)

    # take all the sets of reservations and get stats on them
    equipment_info = full_set.equipment_info
    eq_model_info = equipment_info[0]
    category_info = equipment_info[1]
    #reserver_info = full_set.user_info

    # sets of reservations are passed in by name then models associated
    all_models = [ResSetInfo.new('All Models', :equipment_model_id)]

    res_sets = { total: all_models, #users: reserver_info,
                  categories: category_info, equipment_models: eq_model_info }
    @data_tables = {}
    res_sets.each do |name, info_struct|
      @data_tables[name] = collect_stat_set(info_struct, res_rels)
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
  def build_relations_set(res_set, rel_hash = nil, options = nil)
    # reservation relations for each of the scopes
    rel_hash ||= { :"Total" => nil, :"Reserved" => :reserved,
                   :"Checked Out" => :checked_out, :"Overdue" => :overdue,
                   :"Returned On Time" => :returned_on_time,
                   :"Returned Overdue" => :returned_overdue,
                   :"Missed" => :missed }

    def_options = { stat_type: :count }
    def_options.merge!(options) if options

    res_rels = []
    rel_hash.each do |key, value|
      rel = value ? res_set.send(value) : res_set
      res_rels << ResRelation.new(key.to_s, rel, def_options)
    end
    res_rels
  end

  # build the canned report for a model/set of models
  # rubocop:disable MultilineOperationIndentation, MethodLength, AbcSize
  def models_subreport(ids, start_date, end_date, eq_models)
    res_set = Reservation.includes(:equipment_model, :equipment_object)
                         .starts_on_days(start_date, end_date)
                         .where(equipment_model_id: ids)
    res_rels = build_relations_set(res_set)
    res_rels << ResRelation.new('Avg Planned Duration', res_set,
                                id_type: :equipment_model_id,
                                stat_type: :duration)
    res_rels << ResRelation.new('Avg Duration Checked Out', res_set,
                                id_type: :equipment_model_id,
                                stat_type: :time_checked_out)

    em_info = eq_models.collect do |em|
      em_link = ids.size > 1 ? for_model_report_path(id: em.id) : nil
      ResSetInfo.new(em.name, :equipment_model_id, [em.id], em_link)
    end
    em_stats = collect_stat_set(em_info, res_rels)

    # collect data for users table
    reserver_ids = res_set.collect(&:reserver_id).uniq
    users = User.find(reserver_ids)
    user_info = users.collect do |user|
      ResSetInfo.new(user.name, :reserver_id, [user.id],
                     user_path(id: user.id))
    end
    user_stats = collect_stat_set(user_info, res_rels)

    # collect data by equipment object
    eq_objects = EquipmentObject.where(equipment_model_id: ids)
    obj_info = eq_objects.collect do |obj|
      ResSetInfo.new(obj.name, :equipment_object_id, [obj.id])
    end
    obj_stats = collect_stat_set(obj_info, res_rels)

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
      return res_set.avg_duration
    when :time_checked_out
      return res_set.time_checked_out
    end
  end

  def collect_stat_set(info_struct, res_rels) # rubocop:disable all
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
