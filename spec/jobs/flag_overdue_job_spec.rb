# frozen_string_literal: true
require 'spec_helper'

describe FlagOverdueJob, type: :job do
  it_behaves_like 'flag job', { overdue: true }, :newly_overdue
end
