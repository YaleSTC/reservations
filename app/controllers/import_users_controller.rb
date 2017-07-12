# frozen_string_literal: true

class ImportUsersController < ApplicationController
  include CsvImport
  helper UsersHelper

  authorize_resource class: false

  # functions like the RESTful create action by submitting a POST request to
  # create/update a bunch of users, and it renders the 'imported' page.
  def import
    # initialize
    file = params[:csv_upload] # the file item
    if file
      user_type = params[:user_type]
      overwrite = (params[:overwrite] == '1') # update existing users?
      filepath = file.tempfile.path # the rails CSV class needs a filepath

      imported_users = csv_import(filepath)
    end

    # check if input file is valid and return appropriate error message if not
    return unless valid_input_file?(imported_users, file)
    # create the users and exit
    @hash_of_statuses = import_users(imported_users, overwrite, user_type)
    render 'imported'
  end

  # functions like the RESTful new action by rendering a form with a GET request
  def import_page
    # limits the options for user.role to the following array, and displays
    # them with more user-friendly labels.
    @select_options = [%w[Patrons normal], ['Checkout Persons', 'checkout'],
                       %w[Administrators admin], ['Banned Users', 'banned']]
    render 'import' # a form for uploading a csv file of users to import
  end

  private

  # this method checks that the user has uploaded a file and displays flash
  # messages if there is an error. Putting these validations in the
  # controller is not idiomatic in rails and there is likely a cleaner way to
  # do this. If we ever have to validate more input than this, we should
  # remove this to a csv_import validations model.
  #
  # disabled all rubocop method validations pending import rewrite
  def valid_input_file?(imported_users, file) # rubocop:disable all
    # check if the user has uploaded a file at all.
    unless file
      flash[:error] = 'Please select a file to upload.'
      redirect_back(fallback_location: root_path) && return
    end

    # make sure import from CSV didn't totally fail
    if imported_users.nil?
      flash[:error] = 'Unable to import CSV file. Please ensure it matches '\
        'the import format, and try again.'
      redirect_back(fallback_location: root_path) && return
    end

    # make sure we have username data (otherwise all will always fail)
    unless imported_users.first.keys.include?(:username) ||
           ENV['CAS_AUTH'].nil?
      flash[:error] = 'Unable to import CSV file. None of the users will be '\
        'able to log in without specifying \'username\' data.'
      redirect_back(fallback_location: root_path) && return
    end

    # make sure the import went with proper headings / column handling
    accepted_keys = %i[username first_name last_name nickname phone
                       email affiliation]
    unless imported_users.first.keys == accepted_keys
      flash[:error] = 'Unable to import CSV file. Please ensure that the '\
        'first line of the file exactly matches the sample input (username, '\
        'first_name, etc.) Note that headers are case sensitive, and must be '\
        'in the correct order.'
      redirect_back(fallback_location: root_path) && return
    end
    true
  end
end
