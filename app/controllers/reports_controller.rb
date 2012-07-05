class ReportsController < ApplicationController
  # before_filter :require_admin
  ResRelation = Struct.new(:name, :relation, :params) # relations to build data columns
  StatRow = Struct.new(:name, :data, :link_path) # output structure
  ResSetInfo = Struct.new(:name, :id_type, :ids, :link_path) #info for a reservation set
  
  def index
    @res_stat_sets = []
    @start_date = Date.today.beginning_of_year
    @end_date = Date.today
    #need some kind of admin priveleges before hand...
    users = [current_user]

    # res_set = Reservation.starts_on_days(@start_date,@end_date).reserver_is_in(users)
    full_set = Reservation.starts_on_days(@start_date,@end_date).includes(:equipment_model)
    res_rels = default_relations(full_set)
    res_rels << ResRelation.new("User Count", full_set, 
    {:id_type => :equipment_model_id, :stat_type => :count, :secondary_id => :reserver_id})

    # should this be redone?  Mostly done in two parts to only collect the uniq ids
    eq_model_ids = full_set.collect {|res| res.equipment_model_id}.uniq 
    eq_models = EquipmentModel.includes(:category).find(eq_model_ids)
    
    eq_model_names = []
    category_names = []
    
    cat_info = {}
    eq_models.each do |em|
      eq_model_names << ResSetInfo.new(em.name, :equipment_model_id, [em.id],for_model_report_path(:id => em.id))
      if cat_info[em.category.id]
        cat_info[em.category.id] << em.id
      else
        cat_info[em.category.id] = [em.id]
      end
    end
    categories = Category.find(cat_info.keys)
    categories.each do |cat|
      category_names << ResSetInfo.new(cat.name,:equipment_model_id, cat_info[cat.id], for_model_set_reports_path({:ids => cat_info[cat.id]}))
    end

    # take all the sets of reservations and get stats on them
    # sets of reservations are passed in by name then models associated
    all_models = [ResSetInfo.new("All Models", :equipment_model_id)]
    res_sets = [all_models, category_names, eq_model_names]
    @table_col_names = res_rels.collect{|r| r[:name]} # + [:"User Counts"]
    res_sets.each do |info_struct|
      @res_stat_sets << collect_stat_set(info_struct,res_rels)
    end
  end

  #sub report for a particular model
  def for_model
    @model_tables = models_subreport([params[:id]])
  end
  
  #should probably merge with for_model
  def for_model_set
    @model_tables = models_subreport(params[:ids])
  end
  
  private
  def default_relations(res_set,*conditions)
    # reservation relations for each of the scopes
    res_rels = []
    res_rels << ResRelation.new("Total", res_set)
    res_rels << ResRelation.new("Reserved", res_set.reserved)
    res_rels << ResRelation.new("Checked Out", res_set.checked_out)
    res_rels << ResRelation.new("Overdue", res_set.overdue)
    res_rels << ResRelation.new("Reserved", res_set.returned)
    res_rels << ResRelation.new("Missed", res_set.missed)
    res_rels << ResRelation.new("Upcoming", res_set.upcoming)
    defaults = {:stat_type => :count}
    defaults.merge!(conditions.first) unless conditions.empty?
    res_rels.each do |r|
      if r.params
        r.params = defaults
      else
        r.params = {}
        defaults.each {|key, val| r.params[key] ||= val}
      end
    end
    return res_rels
  end
  
  def models_subreport(ids)
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