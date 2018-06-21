# frozen_string_literal: true

require 'spec_helper'
require 'concerns/soft_deletable_spec.rb'

describe CheckoutProcedure, type: :model do
  it_behaves_like 'soft deletable'

  it { is_expected.to belong_to(:equipment_model) }
end
