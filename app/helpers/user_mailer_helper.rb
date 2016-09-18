# frozen_string_literal: true
module UserMailerHelper
  VARIABLES = { '@user@' => :reserver,
                '@reservation_id@' => :reservation_id,
                '@department_name@' => :dept_name,
                '@equipment_list@' => :equipment_list,
                '@return_date@' => :return_date,
                '@start_date@' => :start_date,
                '@late_fee@' => :late_fee,
                '@replacement_fee@' => :replacement_fee,
                '@tos@' => :tos }.freeze

  def replace_variables(body)
    return '' if body.nil?
    body.dup.tap do |m|
      VARIABLES.each { |variable, method| m.gsub!(variable, send(method)) }
    end
  end

  private

  def reserver
    @reservation.reserver.name
  end

  def reservation_id
    @reservation.id.to_s
  end

  def dept_name
    @app_configs.department_name
  end

  def equipment_list
    @reservation.equipment_model.name
  end

  def return_date
    @reservation.due_date.to_s(:long)
  end

  def start_date
    @reservation.start_date.to_s(:long)
  end

  def late_fee
    number_to_currency(@reservation.equipment_model.late_fee)
  end

  def replacement_fee
    number_to_currency(@reservation.equipment_model.replacement_fee)
  end

  def tos
    @app_configs.terms_of_service
  end
end
