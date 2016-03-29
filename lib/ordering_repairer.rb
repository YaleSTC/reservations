# frozen_string_literal: true
class OrderingRepairer
  attr_reader :category
  def initialize(category)
    @category = category
    @category_id = category.id
    @category_count = category.active_model_count
  end

  def handle_deactivated
    category.inactive_models.each do |model|
      model.update_attribute('ordering', -1) if model.ordering != -1
    end
  end

  def fix_indices(index_set, missing_indices)
    index_set.each do |index|
      model = EquipmentModel.where(category_id: @category_id,
                                   ordering: index).first
      model.update_attribute('ordering', missing_indices.shift)
    end
  end

  def handle_duplicates(missing_indices, orderings)
    duplicates = orderings.find_all do |e|
      orderings.rindex(e) != orderings.index(e)
    end
    duplicates.uniq.each { |d| duplicates.delete_at(duplicates.find_index(d)) }
    fix_indices(duplicates, missing_indices)
  end

  def handle_out_of_bounds(missing_indices, orderings)
    out_of_bounds = orderings.find_all { |e| e > @category_count || e < 1 }
    fix_indices(out_of_bounds, missing_indices)
  end

  def repair
    handle_deactivated
    active_models = category.active_models
    orderings = active_models.map(&:ordering).sort
    return unless orderings != (1..orderings.length).to_a
    missing_indices = (1..orderings.length).to_a - orderings
    handle_duplicates(missing_indices, orderings)
    handle_out_of_bounds(missing_indices, orderings)
  end
end
