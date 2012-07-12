class ReportsController < ApplicationController
  before_filter :require_admin
  ResRelation = Struct.new(:name, :relation, :params) # relations to build data columns
  StatRow = Struct.new(:name, :data, :link_path) # output structure
  ResSetInfo = Struct.new(:name, :id_type, :ids, :link_path) #info for a reservation set (rows of data)
  DetailInfo = Struct.new(:name, :table, :params) # stores the info for building columns

  def index
    @res_stat_sets = []
    @start_date = start_date
    @end_date = end_date
    # users = [current_user]

    # res_set = Reservation.starts_on_days(@start_date,@end_date).reserver_is_in(users)
    full_set = Reservation.starts_on_days(@start_date,@end_date).includes(:equipment_model)
    res_rels = default_relations(full_set)
    res_rels << ResRelation.new("User Count", full_set, 
    {:id_type => :equipment_model_id, :stat_type => :count, :secondary_id => :reserver_id})

    # should this be redone?  Mostly done in two parts to only collect the uniq ids
    eq_model_ids = full_set.collect {|res| res.equipment_model_id}.uniq 
    eq_models = EquipmentModel.includes(:category).find(eq_model_ids)

    eq_model_info = []

    cat_em_ids = {}
    eq_models.each do |em|
      eq_model_info << ResSetInfo.new(em.name, :equipment_model_id, [em.id],for_model_report_path(:id => em.id))
      if cat_em_ids[em.category.id]
        cat_em_ids[em.category.id] << em.id
      else
        cat_em_ids[em.category.id] = [em.id]
      end
    end
    # commented out for speed
    # reserver_ids = full_set.collect {|res| res.reserver_id}.uniq 
    # reservers = User.find(reserver_ids)
    # reserver_info = reservers.collect {|user| ResSetInfo.new(user.name,:reserver_id, [user.id],user_path(:id => user.id))}

    categories = Category.find(cat_em_ids.keys)
    category_info = categories.collect {|cat| ResSetInfo.new(cat.name,:equipment_model_id, cat_em_ids[cat.id],
    for_model_set_reports_path({:ids => cat_em_ids[cat.id]})) }

    # take all the sets of reservations and get stats on them
    # sets of reservations are passed in by name then models associated
    all_models = [ResSetInfo.new("All Models", :equipment_model_id)]

    # commented out for speed
    # res_sets = {:total => all_models, :users => reserver_info, :categories => category_info, :equipment_models => eq_model_info}
    res_sets = {:total => all_models, :categories => category_info, :equipment_models => eq_model_info}
    @data_tables = {}
    res_sets.each do |name,info_struct|
      @data_tables[name] = collect_stat_set(info_struct,res_rels)
    end
    respond_to do |format| 
      format.html          
      format.csv { render :layout => false }
    end
  end
  
  def update_report
    @start_date = (Date.strptime(params[:report][:start_date],'%m/%d/%Y'))
    @end_date = (Date.strptime(params[:report][:end_date],'%m/%d/%Y'))
    session[:report_start_date] = @start_date
    session[:report_end_date] = @end_date
    
    respond_to do |format|
      format.js{render :template => "reports/report_dates_reload"}
      # guys i really don't like how this is rendering a template for js, but :action doesn't work at all
      format.html{render :partial => "reports/report_dates"} # delete this line? replace with redirect_to root_path ? otherwise it's not doing any harm
    end
    # @end_date = (Date.strptime(params[:report][:end_date],'%m/%d/%Y'))
  end

  #sub report for a particular model
  def for_model
    @equipment_model = EquipmentModel.find(params[:id])
    @start_date = start_date
    @end_date = end_date
    @data_tables = models_subreport([params[:id]],@start_date,@end_date, [@equipment_model])
  end

  #should probably merge with for_model
  def for_model_set
    @equipment_models = EquipmentModel.find(params[:ids])
    @start_date = start_date
    @end_date = end_date
    @data_tables = models_subreport(params[:ids],@start_date,@end_date, @equipment_models)
  end

  private
  def start_date
    date = session[:report_start_date] ? session[:report_start_date] : Date.today.beginning_of_year
    return date
  end

  def end_date
    date = session[:report_end_date] ? session[:report_end_date] : Date.today
    return date
  end

  def default_relations(res_set,rel_hash = nil,options = nil)
    # reservation relations for each of the scopes
    rel_hash ||= {:"Total" => nil, :"Reserved" => :reserved, :"Checked Out" => :checked_out, :"Overdue" => :overdue,
                  :"Returned On Time" => :returned_on_time, :"Returned Overdue" => :returned_overdue, :"Missed" => :missed}

    def_options = {:stat_type => :count}
    def_options.merge!(options) if options

    res_rels = []
    rel_hash.each do |key, value|
      rel = value ? res_set.send(value) : res_set
      res_rels << ResRelation.new(key.to_s,rel,def_options)
    end
    return res_rels
  end

  def models_subreport(ids,start_date,end_date,eq_models)
    res_set = Reservation.includes(:equipment_model,:equipment_object).starts_on_days(start_date,end_date).where(:equipment_model_id => ids)
    res_rels = default_relations(res_set)
    res_rels << ResRelation.new("Avg Planned Duration", res_set, {:id_type => :equipment_model_id, :stat_type => :duration,
                                :secondary_id => {:date_type1 => :start_date, :date_type2 => :due_date}})
    res_rels << ResRelation.new("Avg Duration Checked Out", res_set, {:id_type => :equipment_model_id, :stat_type => :duration,
                                :secondary_id => {:date_type1 => :checked_out, :date_type2 => :checked_in, :catch2 => Date.today}})

    eq_info = eq_models.collect do |em|
      em_link = ids.size > 1 ? for_model_report_path(:id => em.id) : nil
      ResSetInfo.new(em.name,:equipment_model_id, [em.id], em_link)
    end
    em_stats = collect_stat_set(eq_info,res_rels)

    reserver_ids = res_set.collect{|r| r.reserver_id}.uniq
    users = User.find(reserver_ids)
    user_info = users.collect {|user| ResSetInfo.new(user.name,:reserver_id, [user.id], user_path(:id => user.id))}
    user_stats = collect_stat_set(user_info,res_rels)

    eq_objects = EquipmentObject.find(:all, :conditions => {:equipment_model_id => ids})
    obj_info = eq_objects.collect {|obj| ResSetInfo.new(obj.name,:equipment_object_id, [obj.id])}
    obj_stats = collect_stat_set(obj_info,res_rels)
    
    det_structs = [DetailInfo.new("Reserver",users,{:secondary_id => :reserver_id, :info_type => :name}),
                   DetailInfo.new("Equipment Model",eq_models,{:secondary_id => :equipment_model_id, :info_type => :name}),
                   DetailInfo.new("Equipment Object",eq_objects,{:secondary_id => :equipment_object_id, :info_type => :name})]
    
    fields = {:status_for_report => nil, :start_date => {:call =>:to_date}, :due_date => {:call =>:to_date},
              :checked_out => {:call =>:to_date}, :checked_in => {:call =>:to_date}}
    res_stats = collect_res_info(res_set,det_structs, fields)
    
    # model_tables = {:equipment_models => em_stats,:equipment_objects => obj_stats, :users => user_stats}
    model_tables = {:equipment_models => em_stats,:equipment_objects => obj_stats, :users => user_stats, :reservations => res_stats}
    return model_tables
  end

  def collect_stat_set(info_struct,res_rels) # iterate by row
    stat_set = {}
    stat_set[:rows] = []
    stat_set[:col_names] = res_rels.collect{|res| res[:name]}
    info_struct.each do |info|
      stat_row = StatRow.new(info.name,[],info.link_path)
      res_rels.each do |rel_struct|
        rel = rel_struct[:relation]
        params = rel_struct[:params]
        # select the reservations whose id of :id_type that are in the array of ids 
        # e.g. equipment_model_id is a member of [1,2,3]
        res_set = info.ids ? rel.select{|res| info.ids.include?(res.send(info.id_type))} : rel.all
        case params[:stat_type]
        when :count
          if params[:secondary_id] #count how many unique 
            stat_row.data << res_set.collect{|res| res.send(params[:secondary_id])}.uniq.count
          else
            stat_row.data << res_set.count
          end
        when :duration # get an average duration for the set of reservations, catch1 && catch2 are used if date1 and date2 are NULL
          # put the dates in chronological order, e.g. :date_type1 => :start_date, :date_type2 => :due_date
          date_type1 = params[:secondary_id][:date_type1]
          date_type2 = params[:secondary_id][:date_type2]
          durations = res_set.collect do |res|
            date1 = res.send(date_type1)
            date1 ||=  params[:secondary_id][:catch1] if params[:secondary_id][:catch1]
            date2 = res.send(date_type2)
            date2 ||=  params[:secondary_id][:catch2] if params[:secondary_id][:catch2]
            
            date1 && date2 ? date2.to_date - date1.to_date : nil
          end
          durations.compact!
          if durations.count > 0
            stat_row.data << (durations.inject{|sum,k| sum + k}.to_f / durations.count).round(2) #avg planned duration
          else
            stat_row.data << "N/A"
          end
        end
      end
      stat_set[:rows] << stat_row
    end
    return stat_set
  end

  # stupid default scope for users, messes with includes, so it ends up doing many more queries than necessary
  # thus this function was written for users
  # pulls details from associated tables and assigns them per reservation
  # hard to do as a join because you need to also run object functions on them.  Still probably should be rewritten
  def assoc_details(tables,res_set)
    col_hash = {}
    tables.each do |table_struct| #collects the info once per id
      table = table_struct.table
      params = table_struct.params
      table_hash = {}
      table.each {|item| table_hash[item.id] = item.send(params[:info_type])}
      stat_arr = []
      res_set.each do |res|
        stat_arr << table_hash[res.send(params[:secondary_id])]
      end
      col_hash[table_struct.name] = stat_arr
    end
    return col_hash
  end
  
  # for the creation of 
  def collect_res_info(res_set, det_structs = nil, fields = {}) # collect information on the set of reservations
    det_columns = det_structs ? assoc_details(det_structs,res_set) : {}
    fields.each do |f,option|
      det_columns[f] = res_set.collect do |res|
        if option && option[:call] 
          res.send(f) ? res.send(f).send(option[:call]) : "N/A"
        else
          res.send(f)
        end
      end
    end
    res_stats = {}
    res_stats[:col_names] = det_columns.keys.collect{|key| key.to_s.titleize}
    res_stats[:rows] = res_set.collect {|res| StatRow.new(res.id,[])}
    det_columns.each do |key, col|
      col.each_index do |ind|
        res_stats[:rows][ind].data << col[ind]
      end
    end
    return res_stats
  end
end