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
    item_file = params[:item_upload]

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
        @equipment_models = @model_statuses[:success]
      else
        redirect_to(:back) && return
      end
    end

    # finally, import EquipmentItems
    if item_file
      # no overwrite parameter since there is no primary key for EquipmentItems
      # store the filepath
      item_filepath = item_file.tempfile.path
      processed_items = csv_import(item_filepath)

      if valid_item_import?(processed_items, item_file)
        @item_statuses = import_items(processed_items)
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
