# frozen_string_literal: true
class OrderingHelper
  attr_reader :eq_mod

  def initialize(eq_mod)
    @eq_mod = eq_mod
  end

  def up
    return unless ordering > cat_first
    new_ordering = rel_predecessor(ordering)
    swap(predecessor, ordering, new_ordering)
  end

  def down
    return unless ordering < cat_last
    new_ordering = rel_successor(ordering)
    swap(successor, ordering, new_ordering)
  end

  def deactivate_order
    current_last = cat_last
    ms = successors
    ms.each do |m|
      m.update_attribute('ordering', rel_predecessor(m.ordering))
    end
    eq_mod.update_attribute('ordering', current_last)
  end

  private

  delegate :ordering, :category_id, to: :eq_mod

  def rel_ordering
    abs_to_rel(eq_mod.ordering)
  end

  def category_orderings
    @category_ordering ||= @eq_mod.category_ordering
  end

  def cat_last
    category_orderings[-1]
  end

  def cat_first
    category_orderings[0]
  end

  def abs_to_rel(n)
    category_orderings.index(n)
  end

  def rel_to_abs(n)
    category_orderings[n]
  end

  def rel_successor(n)
    rel_to_abs(abs_to_rel(n) + 1)
  end

  def rel_predecessor(n)
    rel_to_abs(abs_to_rel(n) - 1)
  end

  def successor
    @successor ||= EquipmentModel.where(ordering: rel_successor(ordering),
                                        deleted_at: nil).first
  end

  def predecessor
    @predecessor ||= EquipmentModel.where(ordering: rel_predecessor(ordering),
                                          deleted_at: nil).first
  end

  def swap(target, old_ordering, new_ordering)
    target.update_attribute('ordering', old_ordering)
    eq_mod.update_attribute('ordering', new_ordering)
  end

  def successors
    EquipmentModel.where('ordering > ?', ordering)
  end
end
