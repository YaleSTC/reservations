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
      res = Reservation.for_eq_model(object)
            .reserved_in_date_range(Date.current - 1.day, Date.current + 7.days)
            .not_returned.count
      onclick_str = "handleBigDeactivation(this, #{res}, 'equipment model');"
    end
    super(onclick_str)
  end
end
