class ReportsController < ApplicationController
  # before_filter :require_admin
  ResRelation = Struct.new(:name, :relation, :params) # relations to build data columns
  StatRow = Struct.new(:name, :data, :link_path) # output structure
  ResSetInfo = Struct.new(:name, :id_type, :ids, :link_path) #info for a reservation set
  
  def index
    
    @res_stat_sets = []
    @start_date = session[:report_start_date] ? session[:report_start_date] : Date.today.beginning_of_year
    @end_date ||= Date.today
    #need some kind of admin priveleges before hand...
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
    #    reservers = User.find(reserver_ids)
    #    reserver_info = reservers.collect {|user| ResSetInfo.new(user.name,:reserver_id, [user.id],user_path(:id => user.id))}
    
    categories = Category.find(cat_em_ids.keys)
    category_info = categories.collect {|cat| ResSetInfo.new(cat.name,:equipment_model_id, cat_em_ids[cat.id],
                                                 for_model_set_reports_path({:ids => cat_em_ids[cat.id]})) }

    # take all the sets of reservations and get stats on them
    # sets of reservations are passed in by name then models associated
    all_models = [ResSetInfo.new("All Models", :equipment_model_id)]
    
    # commented out for speed
    # res_sets = {:total => all_models, :users => reserver_info, :categories => category_info, :equipment_models => eq_model_info}
    res_sets = {:total => all_models, :categories => category_info, :equipment_models => eq_model_info}
    @table_col_names = res_rels.collect{|r| r[:name]} # + [:"User Counts"]
    @data_tables = {}
    res_sets.each do |name,info_struct|
      @data_tables[name] = collect_stat_set(info_struct,res_rels)
    end
  end

  #not working at all right now
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
    @data_tables = models_subreport([params[:id]])
  end
  
  #should probably merge with for_model
  def for_model_set
    @data_tables = models_subreport(params[:ids])
  end
  

  
  private
  def default_relations(res_set,rel_hash = nil,options = nil)
    # reservation relations for each of the scopes
    rel_hash ||= {:"Total" => nil, :"Reserved" => :reserved, :"Checked Out" => :checked_out, :"Overdue" => :overdue,
                  :"Returned" => :returned, :"Missed" => :missed, :"Upcoming" => :upcoming}
    
    def_options = {:stat_type => :count}
    def_options.merge!(options) if options
    
    res_rels = []
    rel_hash.each do |key, value|
      rel = value ? res_set.send(value) : res_set
      res_rels << ResRelation.new(key.to_s,rel,def_options)
    end
    return res_rels
  end
  
  def models_subreport(ids)
    binding.pry
    res_set = Reservation.includes(:equipment_model,:equipment_object).where(:equipment_model_id => ids)
    res_rels = default_relations(res_set)
    res_rels << ResRelation.new("Average Duration", res_set, {:id_type => :equipment_model_id, :stat_type => :duration})
    @table_col_names = res_rels.collect{|r| r[:name]}
    
    eq_models = EquipmentModel.find(ids)
    eq_info = eq_models.collect do |em|
      em_link = ids.size > 1 ? for_model_report_path(:id => em.id) : nil
      ResSetInfo.new(em.name,:equipment_model_id, [em.id], em_link)
    end
    @stat_set = collect_stat_set(eq_info,res_rels)
    
    user_ids = res_set.collect{|r| r.reserver_id}.uniq
    users = User.find(user_ids)
    user_info = users.collect {|user| ResSetInfo.new(user.name,:reserver_id, [user.id], user_path(:id => user.id))}
    user_set = collect_stat_set(user_info,res_rels)
    
    eq_objects = EquipmentObject.find(:all, :conditions => {:equipment_model_id => ids})
    obj_info = eq_objects.collect {|obj| ResSetInfo.new(obj.name,:equipment_object_id, [obj.id])}
    obj_set = collect_stat_set(obj_info,res_rels)
    
    model_tables = {:equipment_models => @stat_set,:equipment_objects => obj_set, :users => user_set}
    return model_tables
  end

  def collect_stat_set(info_struct,res_rels)
    stat_set = []
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
          if params[:secondary_id]
            stat_row.data << res_set.collect{|r| r.send(params[:secondary_id])}.uniq.count
          else
            stat_row.data << res_set.count
          end
        when :duration
          durations = res_set.collect{|res| res.due_date.to_date - res.start_date.to_date}
          stat_row.data << (durations.inject{|sum,k| sum + k}.to_f / durations.count).round(2) #avg planned duration
        end
      end
      stat_set << stat_row
    end
    return stat_set
  end
end