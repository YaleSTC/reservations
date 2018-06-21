# frozen_string_literal: true

class CheckinProcedure < ApplicationRecord
  include SoftDeletable

  belongs_to :equipment_model

  private

  # No associated records for soft deletion
  def associated_records
    []
  end
end
