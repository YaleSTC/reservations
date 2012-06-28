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
    # binding.pry
    # should this be redone?  Mostly done in two parts to only collect the uniq ids
    eq_model_ids = [nil]
    eq_model_ids += full_set.collect {|res| res.equipment_model_id}.uniq 
    
    eq_model_names = {}
    EquipmentModel.find(eq_model_ids).each do |em|
      eq_model_names[em.id] = em.name.to_sym
    end
    
    
    eq_model_ids.each do |model_id|
      res_counts = {}
      res_rels.each do |key, rel|
        if model_id
          res_counts[key] = rel.where(:equipment_model_id => model_id).count
        else
          res_counts[key] = rel.count
        end
      end
      if model_id
        @res_stat_sets[eq_model_names[model_id]] = res_counts
      else
        @res_stat_sets[:"All Models"] = res_counts
      end
    end
    
    
    # scopes.each do |scope|
    #       res_counts[scope] = res_set.method(scope).call.count
    #     end
    
    #durations
    
  end
  
end