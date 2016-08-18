# frozen_string_literal: true
require 'spec_helper'

describe FlagMissedJob, type: :job do
  it_behaves_like 'flag job', { status: 'missed' }, :newly_missed
end
