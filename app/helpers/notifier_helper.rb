module NotifierHelper
  def replace_variables(body)
    return "" if body.nil?
    body.gsub("@user@", @reservation.reserver.name).gsub("@reservation_id@", @reservation.id.to_s).gsub("@department_name@", Settings.department_name).gsub("@equipment_list@", @reservation.equipment_list).gsub("@return_date@", @reservation.due_date.to_date.to_s(:long)).gsub("@late_fee@", number_to_currency(@reservation.late_fee))
  end
end
