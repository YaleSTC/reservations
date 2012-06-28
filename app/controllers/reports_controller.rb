class ReportsController < ApplicationController
  # before_filter :require_admin
  def index
    @start_date = Date.today.beginning_of_year
    @end_date = Date.today
    #need some kind of admin priveleges before hand...
    users = [current_user]
    
    # res_set = Reservation.starts_on_days(@start_date,@end_date).reserver_is_in(users)
    full_set = Reservation.starts_on_days(@start_date,@end_date).includes(:equipment_model)
    @res_stat_sets = {}
    
    # reservation relations for each of the scopes
    res_rels = {}
    res_rels[:total]        = full_set
    res_rels[:reserved]     = full_set.reserved
    res_rels[:checked_out]  = full_set.checked_out
    res_rels[:overdue]      = full_set.overdue
    res_rels[:returned]     = full_set.returned
    res_rels[:missed]       = full_set.missed
    res_rels[:upcoming]     = full_set.upcoming
    
    res_sets = [:all_models]
    
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
    res_sets.each do |name_hash|
      name_hash.each do |name, model_ids|
        res_counts = {}
        res_rels.each do |key, rel|
          if model_ids
            res_counts[key] = rel.select{|res| model_ids.include?(res.equipment_model_id)}.count
          else
            res_counts[key] = rel.count
          end
        end
        
        @res_stat_sets[name] = res_counts
      end
    end
    
    #durations
    
  end
  
end