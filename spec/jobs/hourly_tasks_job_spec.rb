# frozen_string_literal: true
require 'spec_helper'

describe HourlyTasksJob, type: :job do
  it 'enqueues the email notes to admins job' do
    expect(EmailNotesToAdminsJob).to receive(:perform_later)
    described_class.perform_now
  end
end
