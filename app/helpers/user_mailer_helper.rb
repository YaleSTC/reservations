module UserMailerHelper
  def replace_variables(body)
    return '' if body.nil?
    body.gsub!('@user@', @reservation.reserver.name)
    body.gsub!('@reservation_id@', @reservation.id.to_s)
    body.gsub!('@department_name@', @app_configs.department_name)
    body.gsub!('@equipment_list@', @reservation.equipment_model.name)
    body.gsub!('@return_date@', @reservation.due_date.to_date.to_s(:long))
    body.gsub!('@start_date@', @reservation.start_date.to_date.to_s(:long))
    body.gsub!('@late_fee@', number_to_currency(@reservation.late_fee))
    body.gsub!('@replacement_fee@', number_to_currency(@reservation.equipment_model.replacement_fee))
    body.gsub!('@tos@', @app_configs.terms_of_service)
    body
  end
end
