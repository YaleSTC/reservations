class ReportsController < ApplicationController
  # before_filter :require_admin
  ResRelation = Struct.new(:name, :relation, :params)
  StatRow = Struct.new(:name, :link_info, :data)
  
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

    eq_model_names = {}
    category_names = {}

    eq_models.each do |em|
      eq_model_names[em.name.to_sym] = [em.id]
      cat_name = em.category.name.to_sym
      if category_names[cat_name]
        category_names[cat_name] << em.id
      else
        category_names[cat_name] = [em.id]
      end
    end

    # take all the sets of reservations and get stats on them
    # sets of reservations are passed in by name then models associated
    res_sets = [{:"All Models" => nil}, category_names, eq_model_names]
    @table_col_names = res_rels.collect{|r| r[:name]} # + [:"User Counts"]
    res_sets.each do |name_hash|
      @res_stat_sets << collect_stat_set(name_hash,res_rels)
    end
  end

  def for_model
    res_set = Reservation.includes(:equipment_model,:equipment_object).where(:equipment_model_id => params[:id])
    res_rels = default_relations(res_set)
    res_rels << ResRelation.new("Average Duration", res_set, {:id_type => :equipment_model_id, :stat_type => :duration})
    @table_col_names = res_rels.collect{|r| r[:name]}
    
    eq_model = EquipmentModel.find(params[:id])
    name_hash = {eq_model.name.to_sym => [eq_model.id]}
    @stat_set = collect_stat_set(name_hash,res_rels)

    obj_rels = res_rels.each do |r|
      r.params[:id_type] = :equipment_object_id
    end
    eq_objects = EquipmentObject.find(:all, :conditions => {:equipment_model_id => eq_model.id})
    obj_hash = {}
    eq_objects.each do |obj|
      obj_name = obj.name.to_sym 
      obj_hash[obj_name] = [obj.id]
    end
    @obj_set = collect_stat_set(obj_hash,obj_rels)
  end

  private
  def default_relations(res_set,*defaults)
    # reservation relations for each of the scopes
    res_rels = []
    res_rels << ResRelation.new("Total", res_set)
    res_rels << ResRelation.new("Reserved", res_set.reserved)
    res_rels << ResRelation.new("Checked Out", res_set.checked_out)
    res_rels << ResRelation.new("Overdue", res_set.overdue)
    res_rels << ResRelation.new("Reserved", res_set.returned)
    res_rels << ResRelation.new("Missed", res_set.missed)
    res_rels << ResRelation.new("Upcoming", res_set.upcoming)
    defaults = defaults.empty? ? {:id_type => :equipment_model_id, :stat_type => :count} : defaults.first 
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

  def collect_stat_set(name_hash,res_rels)
    stat_set = []
    name_hash.each do |name, ids|
      stat_row = [name]
      res_rels.each do |rel_struct|
        rel = rel_struct[:relation]
        params = rel_struct[:params]
        # select the reservations whose id of :id_type that are in the array of ids 
        # e.g. equipment_model_id is a member of [1,2,3]
        res_set = ids ? rel.select{|res| ids.include?(res.send(params[:id_type]))} : rel.all
        case params[:stat_type]
        when :count
          if params[:secondary_id]
            stat_row << res_set.collect{|r| r.send(params[:secondary_id])}.uniq.count
          else
            stat_row << res_set.count
          end
        when :duration
          durations = res_set.collect{|res| res.due_date.to_date - res.start_date.to_date}
          stat_row << (durations.inject{|sum,k| sum + k}.to_f / durations.count).round(2) #avg planned duration
        end
      end
      stat_set << stat_row
    end
    return stat_set
  end
end