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


end
