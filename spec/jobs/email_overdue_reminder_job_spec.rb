# frozen_string_literal: true
require 'spec_helper'

describe EmailOverdueReminderJob, type: :job do
  it_behaves_like 'email job', { overdue_checkin_email_active?: true }, :overdue
end
