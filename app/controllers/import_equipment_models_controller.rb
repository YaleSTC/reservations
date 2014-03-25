class ImportEquipmentModelsController < ApplicationController
	include CsvImport

	before_filter :require_admin

	# fully modeled after import_users_controller
  def import
  	# initialize
  	file = params[:csv_upload]
    if file
  		overwrite = (params[:overwrite] == '1')
      filepath = file.tempfile.path # the rails CSV class needs a filepath

      imported_equipment = csv_import(filepath)
    end

    if valid_input_file?(imported_equipment, file)
    	# create the equipment and categories and exit
    	@hash_of_statuses = import_equipment(imported_equipment, overwrite)
    	render 'imported'
    end

  end

  def import_page
  	render 'import'
  end

  private

  	# as in import_users_controller, not idiomatic in Rails but good for now
  	def valid_input_file?(imported_equipment, file)
  		# check for file
  		if !file
  			flash[:error] = 'Please select a file to upload.'
  			redirect_to :back and return
  		end

  		# check for total CSV import failure
  		if imported_equipment.nil?
  			flash[:error] = 'Unable to import CSV file. Please ensure it matches the input format and try again.'
  			redirect_to :back and return
  		end

  		# check for proper headings / columns
  		accepted_keys = [:name, :description, :category, :late_fee, :replacement_fee]
  		unless imported_equipment.first.keys == accepted_keys
  			flash[:error] = 'Unable to import CSV file. Please ensure that the first line of the file exactly matches the sample input (name, description, etc.) Note that headers are case sensitive and must be in the correct order.'
  			redirect_to :back and return
  		end
  		return true
  	end

end