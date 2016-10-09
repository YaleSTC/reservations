# frozen_string_literal: true
module ReservationGenerator
  extend ReservationGeneratorHelper

  RES_TYPES = Reservation.statuses.keys + %w(future overdue returned_overdue) -
              %w(reserved)

  # Generate one of each reservation type with fixed time differences and
  # one with random time differences
  def self.generate_all_types
    RES_TYPES.each do |t|
      attempt_res_gen(t)
      attempt_res_gen(t, true)
    end
  end

  # Generate random reservation
  def self.generate_random
    attempt_res_gen(RES_TYPES.sample, true)
  end

  def self.attempt_res_gen(type, random = false)
    50.times do
      res = gen_res(random)
      send("make_#{type}".to_sym, res, random)
      begin
        res.save!
        # save the equipment model for the counter cache updates
        res.equipment_model.save
        return res
      rescue
        res.delete
      end
    end
  end
end
