require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_notes_to_admins' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  STATUSES = [:checked_out_reservation, :checked_in_reservation]

  shared_examples 'sends appropriate emails' do |status|
    let(:notes) do
      n = FactoryGirl.build(status, notes: 'here is a note')
      n.save!(validate: false)
      n
    end
    let(:no_notes) do
      n = FactoryGirl.build(status)
      n.save!(validate: false)
      n
    end

    it "doesn't sends emails for reservations without unsent notes" do
      expect(notes.notes_unsent).to be_falsey
      expect { subject.invoke }.to_not(
        change { ActionMailer::Base.deliveries.count })
    end

    it 'sends emails for appropriate reservations with unsent notes' do
      notes.update_attributes(notes_unsent: true)
      expect(notes.notes_unsent).to be_truthy
      notes.save!(validate: false)
      expect { subject.invoke }.to(
        change { ActionMailer::Base.deliveries.count }.by(1))
    end
  end

  STATUSES.each { |status| it_behaves_like 'sends appropriate emails', status }
end
