# frozen_string_literal: true
class EquipmentModelDecorator < ApplicationDecorator
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
      # find reservations in the next week
      res =
        Reservation.for_eq_model(object.id).active
                   .overlaps_with_date_range(Time.zone.today - 1.day,
                                             Time.zone.today + 7.days)
                   .count
      onclick_str = "handleBigDeactivation(this, #{res}, 'equipment model');"
    end
    super(onclick_str)
  end
end
