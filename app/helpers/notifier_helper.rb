module NotifierHelper
  def replace_variables(body)
    return "" if body.nil?
    body.gsub("@user@", @reservation.reserver.name)
    body.gsub("@reservation_id@", @reservation.id.to_s)
    body.gsub("@department_name@", Settings.department_name)
    body.gsub("@equipment_list@", @reservation.equipment_model.name)
    body.gsub("@return_date@", @reservation.due_date.to_date.to_s(:long))
    body.gsub("@late_fee@", number_to_currency(@reservation.late_fee))
  end
end

