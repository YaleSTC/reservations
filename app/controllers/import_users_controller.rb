class ImportUsersController < ApplicationController


  def import
    @select_options = [['Patrons','normal'],['Checkout Persons','checkout'],['Administrators','admin'],['Banned Users','banned']]

    unless current_user.is_admin_in_adminmode?
      flash[:error] = 'Permission denied.'
      redirect_to root_path and return
    end

    # initialize
    file = params[:csv_upload] # the file object

    # check if the user has uploaded a file at all.
    if !file
      flash[:error] = 'Please select a file to upload.'
      redirect_to :back and return
    end

    user_type = params[:user_type]
    overwrite = (params[:overwrite] == '1') # update existing users?
    filepath = file.tempfile.path # the rails CSV class needs a filepath

    imported_users = csv_import(filepath)

    # check if input file is valid and return appropriate error message if not
    if valid_input_file?(imported_users)
      # create the users and exit
      @hash_of_statuses = User.import_users(imported_users,overwrite,user_type)
      render 'import_success'
    end
  end

  def import_page
    @select_options = [['Patrons','normal'],['Checkout Persons','checkout'],['Administrators','admin'],['Banned Users','banned']]
    render 'import'
  end

  def csv_import(filepath)
    # initialize
    imported_objects = []
    string = File.read(filepath)
    require 'csv'

    # import data by row
    CSV.parse(string, :headers => true) do |row|
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

  private

    def valid_input_file?(imported_users)
      # make sure import from CSV didn't totally fail
      if imported_users.nil?
        flash[:error] = 'Unable to import CSV file. Please ensure it matches the import format, and try again.'
        redirect_to :back and return
      end

      # make sure we have login data (otherwise all will always fail)
      unless imported_users.first.keys.include?(:login)
        flash[:error] = "Unable to import CSV file. None of the users will be able to log in without specifying 'login' data."
        redirect_to :back and return
      end

      # make sure the import went with proper headings / column handling
      accepted_keys = [:login, :first_name, :last_name, :nickname, :phone, :email, :affiliation]
      unless imported_users.first.keys == accepted_keys
        flash[:error] = 'Unable to import CSV file. Please ensure that the first line of the file exactly matches the sample input (login, first_name, etc.) Note that headers are case sensitive and must be in the correct order.'
        redirect_to :back and return
      end
      return true
    end
end
