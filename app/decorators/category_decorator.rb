class CategoryDecorator < ApplicationDecorator
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
      # find reservations for models in the category in the next week
      res = 0
      object.equipment_models.each do |em|
        res += Reservation.for_eq_model(em.id).active
               .overlaps_with_date_range(Time.zone.today - 1.day,
                                         Time.zone.today + 7.days)
               .count
      end
      onclick_str = "handleBigDeactivation(this, #{res}, 'category');"
    end
    super(onclick_str)
  end
end
