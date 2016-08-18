# frozen_string_literal: true
require 'spec_helper'

describe EmailCheckinReminderJob, type: :job do
  it_behaves_like 'email job', { upcoming_checkin_email_active: true },
                  :due_today
end
