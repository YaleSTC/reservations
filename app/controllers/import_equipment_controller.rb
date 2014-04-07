class ImportEquipmentController < ApplicationController
  include CsvImport

  before_filter :require_admin

  # modeled after the ImportUsersController
  def import
  	# initialize, we take up to three CSV files, now we have to check each
  	binding.pry
  	cat_file = params[:cat_upload]
  	model_file = params[:model_upload]
  	object_file = params[:object_upload]

    # if the user uploaded a category CSV file
    if cat_file
      # store the overwrite parameter and filepath
      cat_overwrite = params[:cat_overwrite]
      cat_filepath = cat_file.tempfile.path

      # process the category CSV file
      processed_cats = csv_import(cat_filepath)

      # validate processed categories
      if valid_cat_import?(processed_cats, cat_file)
        # create categories
        @cat_statuses = import_cats(processed_cats, cat_overwrite)
      end
    end

    # next, import the EquipmentModels
    if model_file
      # store the overwrite parameter and filepath
      model_overwrite = params[:model_overwrite]
      model_filepath = model_file.tempfile.path

      # process the equipment model CSV file
      processed_models = csv_import(model_filepath)

      # validate the processed equipment models
      if valid_model_import?(processed_models, model_file)
        # create EquipmentModels
        @model_statuses = import_models(processed_models, model_overwrite)
      end
    end

    # finally, import EquipmentObjects
    if object_file
      # no overwrite paramter since there is no index for EquipmentObjects
      # store the filepath
      object_filepath = object_file.tempfile.path
      processed_objects = csv_import(object_filepath)

      if valid_object_import?(processed_objects, object_file)
        @object_statuses = import_objects(processed_objects)
      end
    end

    # render the import status page
    render 'imported'

  	# OK, so we need to check each file in turn, if it exists save the overwrite parameter and file path, process the CSV file, validate the processed data, attempt to import the data, and then report the import status

  	# we can definitely avoid duplicating the initial code (check for file, store overwrite, process CSV file); maybe store the three files in an array and just loop over it

  	# once we've processed any categories, we then move on to equipment models, making sure to search for the associated categories by name and store the id of the categories (if found)

  	# similarly, after processing any equipment models, we move on to equipment items and search for the associated equipment models by name and store the id (if found)

  	# finally, we need to put together a relatively clean view to summarize the results of each requested import operation.

  	render 'imported'
  end

  def import_page
  	render 'import'
  end

  private

    # THIS STUFF ALL NEEDS TO MOVE TO A LIBRARY AS DISCUSSED WITH AUSTIN. THINK ABOUT THE BEST WAY TO REFACTOR CSV CODE (GENERAL CSV FUNCTIONS, USER-SPECIFIC FUNCTIONS, EQUIPMENT SPECIFIC FUNCTIONS) SO WE CAN CLEAN UP THE CONTROLLER.  ALSO, WE SHOULD WRITE TESTS FOR THE LIBRARIES AND ACTUALLY DO SOME TDD.  THIS ALL APPLIES TO REPORTS AS WELL.

    # Ok, now we need to write the methods that will actually take our processed CSV hashes and try to import them
    def import_cats(processed_cats, cat_overwrite=false)

      @array_of_success = [] # will contain category objects
      @array_of_fail = [] # will contain category_data hashes and error messages

      processed_cats.each do |cat_data|
        cat_data[:csv_import] = true
        # if cat_overwrite and (Category.where())
      end
    end


end
