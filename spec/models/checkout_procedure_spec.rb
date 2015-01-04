require 'spec_helper'

describe CheckoutProcedure, type: :model do
  it { is_expected.to belong_to(:equipment_model) }
end
