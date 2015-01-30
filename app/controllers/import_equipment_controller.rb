class ImportEquipmentController < ApplicationController
  include CsvImport
  include EquipmentImport

  authorize_resource class: false

  # modeled after the ImportUsersController
  # rubocop disabled pending refactoring
  def import # rubocop:disable all
    # initialize, we take up to three CSV files, now we have to check each
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
      else
        redirect_to(:back) && return
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
      else
        redirect_to(:back) && return
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
      else
        redirect_to(:back) && return
      end
    end

    # render the import status page
    render 'imported'
  end

  def import_page
    render 'import'
  end
end
