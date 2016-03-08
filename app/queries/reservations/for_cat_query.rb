module Reservations
  class ForCatQuery < Reservations::ReservationsQueryBase
    def call(cat_id)
      ems = EquipmentModel.where('category_id = ?', cat_id).map(&:id)
      @relation.where(equipment_model_id: ems)
    end
  end
end
