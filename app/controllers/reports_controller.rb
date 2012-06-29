class ReportsController < ApplicationController
  # before_filter :require_admin
  ResRelation = Struct.new(:name, :relation, :params)
  
  def index
    @start_date = Date.today.beginning_of_year
    @end_date = Date.today
    #need some kind of admin priveleges before hand...
    users = [current_user]

    # res_set = Reservation.starts_on_days(@start_date,@end_date).reserver_is_in(users)
    full_set = Reservation.starts_on_days(@start_date,@end_date).includes(:equipment_model)
    @res_stat_sets = {}

    # reservation relations for each of the scopes
    res_rels = []
    res_rels << ResRelation.new("Total", full_set)
    res_rels << ResRelation.new("Reserved", full_set.reserved)
    res_rels << ResRelation.new("Checked Out", full_set.checked_out)
    res_rels << ResRelation.new("Overdue", full_set.overdue)
    res_rels << ResRelation.new("Reserved", full_set.returned)
    res_rels << ResRelation.new("Missed", full_set.missed)
    res_rels << ResRelation.new("Upcoming", full_set.upcoming)
    res_rels << ResRelation.new("User Count", full_set, 
                                {:id_type => :equipment_model_id, :count_type => :reserver_id, :distinct => true})
    
    defaults = {:id_type => :equipment_model_id}
    res_rels.each do |r|
      if r.params
        defaults.each {|key, val| r.params[key] ||= val} 
      else
        r.params = defaults
      end
    end

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
    @res_stat_sets = []
    @table_col_names = res_rels.collect{|r| r[:name]} # + [:"User Counts"]
    res_sets.each do |name_hash|
      @res_stat_sets << collect_stat_set(name_hash,res_rels)
    end
  end

  def collect_stat_set(name_hash,res_rels)
    stat_set = []
    name_hash.each do |name, ids|
      res_counts = [name]
      res_rels.each do |rel_struct|
        rel = rel_struct[:relation]
        params = rel_struct[:params]
        # select the reservations whose id of :id_type that are in the array of ids 
        # e.g. equipment_model_id is a member of [1,2,3]
        res_set = ids ? rel.select{|res| ids.include?(res.send(params[:id_type]))} : rel.all
        if params[:distinct]
          res_counts << res_set.collect{|r| r.send(params[:count_type])}.uniq.count
        else
          res_counts << res_set.count
        end
      end
      stat_set << res_counts
    end
    return stat_set
  end
end