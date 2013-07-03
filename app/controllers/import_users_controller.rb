class ImportUsersController < ApplicationController

  before_filter :require_admin

  def import
    # initialize
    file = params[:csv_upload] # the file object
    if file
      user_type = params[:user_type]
      overwrite = (params[:overwrite] == '1') # update existing users?
      filepath = file.tempfile.path # the rails CSV class needs a filepath

      imported_users = csv_import(filepath)
    end

    # check if input file is valid and return appropriate error message if not
    if valid_input_file?(imported_users, file)
      # create the users and exit
      @hash_of_statuses = import_users(imported_users, overwrite, user_type)
      render 'imported'
    end
  end

  def import_page
    @select_options = [['Patrons','normal'],['Checkout Persons','checkout'],['Administrators','admin'],['Banned Users','banned']]
    render 'import'
  end

  private

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

    def valid_input_file?(imported_users, file)
      # check if the user has uploaded a file at all.
      if !file
        flash[:error] = 'Please select a file to upload.'
        redirect_to :back and return
      end

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

    def import_with_ldap(user_data_hash)
      # check LDAP for missing data
      ldap_user_hash = User.search_ldap(user_data_hash[:login])

      # if nothing found via LDAP
      if ldap_user_hash.nil?
        return
      end

      # fill-in missing key-values with LDAP data
      user_data_hash.keys.each do |key|
        if user_data_hash[key].blank? and !ldap_user_hash[key].blank?
          user_data_hash[key] = ldap_user_hash[key]
        end
      end
      user_data_hash
    end

    def set_or_create_user_for_import(user_data)
      # set the user and attempt to save with given data
      if @overwrite and (User.where("login = ?", user_data[:login]).size > 0)
        user = User.where("login = ?", user_data[:login]).first
      else
        user = User.new(user_data)
      end
      return user
    end

    def attempt_save_with_csv_data?(user_data)
      user = set_or_create_user_for_import(user_data)

      user.update_attributes(user_data)
      # if the updated or new user is valid, save to database and add to array of successful imports
      if user.valid?
        user.csv_import = true
        user.role = @user_type
        user.save
        @array_of_success << user
        return true
      else
        return false
      end
    end

    def attempt_save_with_ldap(user_data)
      ldap_hash = import_with_ldap(user_data)
      if ldap_hash
        user_data = ldap_hash
      else
        @array_of_fail << [user_data, 'Incomplete user information. Unable to find user in online directory (LDAP).']
        return
      end

      user = set_or_create_user_for_import(user_data)

      # set other user attributes
      user.csv_import = true
      user.role = @user_type

      if user.valid?
        user.save
        @array_of_success << user
        return
      else
        @array_of_fail << [user_data, user.errors.full_messages.to_sentence.capitalize + '.']
        return
      end
    end

    def import_users(array_of_user_data, overwrite=false, user_type='normal')
      # give safe defaults if none selected

      @array_of_success = [] # will contain user-objects
      @array_of_fail = [] # will contain user_data hashes and error messages
      @user_type = user_type
      @overwrite = overwrite

      array_of_user_data.each do |user_data|
        if attempt_save_with_csv_data?(user_data)
          next
        else
          attempt_save_with_ldap(user_data)
          next
        end
      end

      hash_of_statuses = {:success => @array_of_success, :fail => @array_of_fail}
    end
end
