require 'spec_helper.rb'

describe "transform_attributes" do
  context "during key transformation" do
    pending "removes underscores"
    pending "capitalizes all first letters"
    pending "uses 'ID'"
  end

  context "with valid values" do
    pending "converts existing reserver ID into proper link"
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

  context "with invalid attributes" do
    pending "doesn't throw an exception"
    pending "returns N/A"
  end
end
