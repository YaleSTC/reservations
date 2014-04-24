require 'spec_helper'

# include the module file
include EquipmentImport
# include CsvImport # I don't like that we have to include this; it makes our
# tests dependent on a separate module (brittle?) --> see below

# method that duplicates the csv_import method from the CsvImport library using a string as the input instead of a filepath... this should almost definitely be refactored!
def csv_import(string)
  # initialize
  imported_objects = []
	require 'csv'

	# import data by row
	CSV.parse(string, headers: true) do |row|
    object_hash = row.to_hash.symbolize_keys

    # make all nil values blank
    object_hash.keys.each do |key|
      if object_hash[key].nil?
        object_hash[key] = ''
      end
    end
    imported_objects << object_hash
  end
  # return array of imported objects
  imported_objects
end

describe EquipmentImport do
	# test for various methods
	describe "should have methods" do
		before { @methods = self.methods }
		it "#import_cats" do
			@methods.should include(:import_cats)
		end
		it "#import_models" do
			@methods.should include(:import_models)
		end
		it "#import_objects" do
			@methods.should include(:import_objects)
		end
		it "#valid_equipment_import?" do
			@methods.should include(:valid_equipment_import?)
		end
		it "#valid_cat_import?" do
			@methods.should include(:valid_cat_import?)
		end
		it "#valid_model_import?" do
			@methods.should include(:valid_model_import?)
		end
		it "#valid_object_import?" do
			@methods.should include(:valid_object_import?)
		end
	end

	# test for category import functionality
	# NOTE: we need test data!!
	describe "when importing categories" do
		context "with valid data" do
			before do
				@cat_data = "name,max_per_user,max_checkout_length,max_renewal_times,max_renewal_length,renewal_days_before_due,sort_order\nDSLRs,1,14,1,7,3,55\nTripodss,,7,2,7,,\nPower Cables,,,,,,99\nPants,,,,,,"
			end
			describe "with override" do
				pending
			end
			describe "without override" do
				pending
			end
		end
		context "with invalid data" do
			describe "with empty csv file" do
				@cat_data = ""
				@processed_cats = csv_import(@cat_data)
				valid_cat_import?(@processed_cats, @cat_data).should be_false
			end
			describe "with invalid header" do
				@cat_data = @cat_data.split("\n")[1..-1].insert(0, "name,max_per_user,max_checkout_length,max_renewal_times,max_renewal_length,renewal_days_before_due").join("\n")
				# damn, I wanted to use the csv_import method from CsvImport but it requires a filepath, not a csv and I think that's way more than we should be doing for these tests. I'm going to define a replacement method at the top of the file... not sure if that's good practice.
				@processed_cats = csv_import(@cat_data)
				pending "write tests"
			end
		end
	end

	# test for model import functionality
	describe "when importing equipment models" do
		context "with valid data" do
			describe "with override" do
				pending
			end
			describe "without override" do
				pending
			end
		end
		context "with invalid data" do
			pending "write tests"
		end
	end

	# test for object import functionality
	describe "when importing equipment objects" do
		context "with valid data" do
			pending
		end
		context "with invalid data" do
			pending "write tests"
		end
	end
end
