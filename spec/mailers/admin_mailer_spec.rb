require 'spec_helper'

describe AdminMailer do

  shared_examples_for "admin email" do
   it "is only sent to one address" do
     expect(mail.to.size).to eq(1)
   end
   it "is to the admin" do
     expect(mail.to.first).to eq(AppConfig.first.admin_email)
   end
   it "delivers" do
     expect { mail.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
   end
  end

  describe 'Notes Reservation Notification' do
   subject(:res){FactoryGirl.build(:valid_reservation, :notes => "notes")}
   subject(:mail) {AdminMailer.notes_reservation_notification(res,res)}
   it_behaves_like "admin email"
  end
  describe 'overdue checked in email' do
   # subject(:res){FactoryGirl.build(:valid_reservation)}
   # subject(:mail) {AdminMailer.overdue_checked_in_fine_admin(res)}
   # it_behaves_like 'admin email'
  end
end
