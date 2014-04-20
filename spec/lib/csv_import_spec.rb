require 'spec_helper'

# include the module file
include CsvImport

describe CsvImport do
	# test for various methods
	pending "should have methods" do
		before { @methods = self.methods }
		it "#method_name" do
			@methods.should include(:method_name)
		end
	end

	# test for other things
	describe "#csv_import" do
		pending "write tests"
	end
end
