# frozen_string_literal: true
require 'spec_helper'

describe EmailCheckoutReminderJob, type: :job do
  it_behaves_like 'email job', { upcoming_checkout_email_active: true },
                  :upcoming
end
