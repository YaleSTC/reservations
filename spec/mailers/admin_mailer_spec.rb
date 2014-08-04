require 'spec_helper'

shared_examples_for "a valid admin email" do
  it "sends to the admin" do
    expect(@mail.to.size).to eq(1)
    expect(@mail.to.first).to eq(@app_config.admin_email)
  end
  it "is from no-reply@reservations.app" do
    expect(@mail.from.size).to eq(1)
    expect(@mail.from.first).to eq("no-reply@reservations.app")
  end
  it "should actually send the email" do
    ActionMailer::Base.deliveries.count.should eq(1)
  end
end

describe AdminMailer do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  let!(:admin) { FactoryGirl.create(:admin) }

  describe 'notes_reservation_notification' do
    before do
      @res1 = FactoryGirl.create(:valid_reservation)
      @res2 = FactoryGirl.create(:valid_reservation)
      @mail = AdminMailer.notes_reservation_notification(@res1,@res2).deliver
    end
    it 'renders the subject' do
      expect(@mail.subject).to eq("[Reservation] Notes for " + (Date.yesterday.midnight).strftime("%m/%d/%y"))
    end
    it_behaves_like "a valid admin email"

  end
  describe 'overdue_checked_in_fine_admin' do
    before do
      @model = FactoryGirl.create(:equipment_model)
      @object = FactoryGirl.create(:equipment_object, equipment_model: @model)
      @res1 = FactoryGirl.build(:checked_in_reservation, equipment_model: @model, equipment_object: @object)
      @res1.save(validate: false)
      @mail = AdminMailer.overdue_checked_in_fine_admin(@res1).deliver
    end
    it_behaves_like "a valid admin email"
    it 'renders the subject' do
      expect(@mail.subject).to eq("[Reservation] Overdue equipment fine")
    end

  end
end
