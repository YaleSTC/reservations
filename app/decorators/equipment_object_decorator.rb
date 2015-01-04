class EquipmentObjectDecorator < ApplicationDecorator
  delegate_all

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def make_deactivate_btn
    unless object.deleted_at
      em = object.equipment_model
      res = object.current_reservation
      overbooked_dates = []
      (Date.current..Date.current + 7.days).each do |date|
        overbooked_dates << date.to_s(:short) if em.available_count(date) <= 0
      end
      onclick_str = "handleDeactivation(this, #{res ? res.id : 'null'}, "\
        "#{overbooked_dates});"
    end
    super(onclick_str)
  end
end
