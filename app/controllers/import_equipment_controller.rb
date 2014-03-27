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

  	render 'imported'
  end

  def import_page
  	render 'import'
  end

  private


end
