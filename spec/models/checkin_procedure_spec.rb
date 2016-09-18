# frozen_string_literal: true
require 'spec_helper'

describe CheckinProcedure, type: :model do
  it { is_expected.to belong_to(:equipment_model) }
end
