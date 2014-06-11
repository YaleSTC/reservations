require 'spec_helper.rb'

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
      xit "transforms nil to N/A" do
        expect { transform_attributes(['not_an_attribute', nil])[1] }.to eq("N/A")
      end
      xit "doesn't transform constant values" do
        [1, true, 'true'].each do |x|
          expect { transform_attributes(['not_an_attribute', x])[1] }.to eq(x)
        end
      end
    end
  end

  context "with recognized key" do
    xit "converts existing reserver ID into proper link" do
      expect { transform_attributes( ['reserver_id', 1] ) }.to eq( ['Reserver ID', link_to('S P', User.find(1))])
    end
    pending "converts existing check-out handler ID into proper link"
    pending "converts existing check-in handler ID into proper link"
    pending "converts existing reservation ID into proper link"
    pending "converts existing equipment model ID into proper link"
    pending "converts existing equipment item ID into proper link"
    pending "converts start date to readable form (Mon DD, YYYY)"
    pending "converts due date to readable form (Mon DD, YYYY)"
    pending "converts check-in time to readable form"
    pending "converts check-out time to readable form"
    pending "converts creation time to readable form"
    pending "converts update time to readable form"

    pending "converts other field values to N/A if nil"
    pending "leaves other field values intact"
  end
end
