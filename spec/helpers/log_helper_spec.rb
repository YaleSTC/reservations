require 'spec_helper.rb'

# Note: Using `expect{}.to` notation for transform_attributes() runs into
# difficulties -- rather than accessing the value returned by function, it
# sees the intermediary Proc. Therefore, the trusty `should` is used instead.

describe "transform_attributes" do
  include LogHelper

  context "with unrecognized key" do
    context "during key transformation" do
      subject { transform_attributes(['id_checked_at_time', nil])[0] }
      it { should_not include '_' }
      it { should include 'I', 'C', 'A', 'T'}
      it { should include 'ID' }
      it { should eq("ID Checked At Time") }
      it { should_not raise_error }
    end

    context "during value transformation" do
      it "transforms nil to N/A" do
        transform_attributes(['not_an_attribute', nil])[1].should == "N/A"
      end
      it "doesn't transform constant values" do
        [1, true, 'true'].each do |x|
          transform_attributes(['not_an_attribute', x])[1].should == x
        end
      end
    end
  end

  context "with recognized key" do
    it "converts existing reserver/check-in handler/check-out handler ID into proper link" do
      user = FactoryGirl.create(:user)
      %w(reserver_id checkin_handler_id checkout_handler_id).each do |k|
        transform_attributes( [k, user.id] )[1].should == link_to(user.name, User.find(user.id))
      end
    end

    it "converts non-existent reserver ID into N/A" do
      %w(reserver_id checkin_handler_id checkout_handler_id).each do |k|
        transform_attributes( [k, nil] )[1].should == 'N/A'
      end
    end

    it "converts existing reservation ID into proper link" do
      res = FactoryGirl.create(:reservation)
      transform_attributes( ['reservation_id', res.id] )[1].should == link_to("#{res.id} (see current)", Reservation.find(res.id))
    end

    it "doesn't convert defunct reservation ID into proper link" do
      transform_attributes( ['reservation_id', 0] )[1].should == "0 (deleted)"
    end

    pending "converts existing equipment model ID into proper link"
    pending "converts existing equipment item ID into proper link"
    pending "converts start date and due date to readable form (Mon DD, YYYY)"
    pending "converts creation, update, check-in, and check-out time to readable form"

    pending "converts other field values to N/A if nil"
    pending "leaves other field values intact"
  end
end
