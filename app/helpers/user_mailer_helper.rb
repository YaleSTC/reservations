module UserMailerHelper
  def replace_variables(body)
    return "" if body.nil?
    body = body.gsub("@user@", @complete_reservation.first.reserver.name)
    body = body.gsub("@reservation_id@", @reservation.id.to_s)
    body = body.gsub("@department_name@", Settings.department_name)
    body = body.gsub("@equipment_list@", @reservation.equipment_model.name)
    body = body.gsub("@return_date@", @reservation.due_date.to_date.to_s(:long))
    body = body.gsub("@late_fee@", number_to_currency(@reservation.late_fee))
  end
end

