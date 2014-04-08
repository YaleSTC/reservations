module EquipmentImport

	# IMPORT FUNCTIONS - these are all kinda similar, but we'll write them separately for now and we can always refactor later.

	# import categories
	def import_cats(processed_cats, cat_overwrite=false)

		# let's make sure that we're consistent w/ scope on these variables
		array_of_success = [] # will contain category objects
		array_of_fail = [] # will contain category_data hashes and error messages

		processed_cats.each do |cat_data|
			cat_data[:csv_import] = true

			# pick or create new category based on overwrite parameter
			if cat_overwrite and (Category.where("name = ?", cat_data[:name]).size > 0)
				cat = Category.where("name = ?", cat_data[:name]).first
			else
				cat = Category.new(cat_data)
			end

			cat.update_attributes(cat_data)
			# if updated / new category is valid, save to database and add to array of success
			if cat.valid?
				cat.save
				array_of_success << cat
			# else, store to array of fail with error messages
			else
				array_of_fail << [cat_data, cat.errors.full_messages.to_sentence.capitalize+'.']
			end
		end

		# return hash of status arrays
		{ success: array_of_success, fail: array_of_fail }

	end

	# VALIDATION FUNCTIONS - not sure if this should be here or if we need to create an import model to validate properly (see import_equipment_controller.rb)
	# ISSUE - I'm not sure if these redirections are working?

	# this is for validations that are true for all imports
	def valid_equipment_import?(processed_stuff, file, type, accepted_keys, key_error)
	  # check for file
	  if !file
	    flash[:error] = 'Please select a file to upload'
	    redirect_to :back and return
	  end

	  # check for total CSV import failure
	  if processed_stuff.nil?
	    flash[:error] = "Unable to import #{type} CSV file.  Please ensure it matches the import format, and try again."
	    redirect_to :back and return
	  end

	  # check for valid keys
	  unless processed_stuff.first.keys == accepted_keys
	    flash[:error] = key_error
	    redirect_to :back and return
	  end

	  return true
	end

	# these next few methods are all very similar, not sure if there's a better way but we'll start with this.
	# category validators
	def valid_cat_import?(processed_cats, cat_file)
    # define accepted keys and key error
    # NOTE: this must match the parameters in the database / model!!
    accepted_keys = [:name, :max_per_user, :max_checkout_length, :max_renewal_times, :max_renewal_length, :renewal_days_before_due]
    key_error = 'Unable to import category CSV file. Please ensure that the first line of the file exactly matches the sample input (name,max_per_user, etc.) Note that headers are case sensitive and must be in the correct order'
    # general validations
    if valid_equipment_import?(processed_cats, cat_file, 'category', accepted_keys, key_error)
      # custom validators for categories go here
      return true
    end
	end

  # model validators
  def valid_model_import?(processed_models, model_file)
    # define accepted keys and key error
    accepted_keys = [:category, :name, :description, :late_fee, :replacement_fee, :max_per_user, :max_length]
    key_error = 'Unable to import equipment model CSV file. Please ensure that the first line of the file exactly matches the sample input (category, name, etc.) Note that headers are case sensitive and must be in the correct order'
    # general validations
    if valid_equipment_import?(processed_models, model_file, 'equipment model', accepted_keys, key_error)
      # custom validators for equipment models go here
      return true
    end
  end

  # object validators
  def valid_object_import?(processed_objects, object_file)
    # define accepted keys and key error
    accepted_keys = [:equipment_model, :name, :serial]
    key_error = 'Unable to import equipment item CSV file. Please ensure that the first line of the file exactly matches the sample input (equipment_model,name,serial) Note that headers are case sensitive and must be in the correct order'
    # general validations
    if valid_equipment_import?(processed_objects, object_file, 'equipment item', accepted_keys, key_error)
      # custom validators for equipment items go here
      return true
    end
  end

end