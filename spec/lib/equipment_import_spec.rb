require 'spec_helper'

# include the module file
include EquipmentImport

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
		pending "write tests"
	end

	# test for model import functionality
	describe "when importing equipment models" do
		pending "write tests"
	end

	# test for object import functionality
	describe "when importing equipment objects" do
		pending "write tests"
	end
end
