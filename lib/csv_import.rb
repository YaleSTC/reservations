# frozen_string_literal: true
module CsvImport
  # method used to convert a csv filepath to an array of objects specified by
  # the file
  def csv_import(filepath)
    # initialize
    imported_objects = []
    string = File.read(filepath)
    require 'csv'

    # sanitize input
    string = string.encode('UTF-8', 'binary',
                           invalid: :replace, undef: :replace, replace: '')

    # remove spaces from header line
    string = string.split(/(\r?\n)|\r/)
    string.first.gsub!(/\s+/, '')
    string.reject! { |s| /(\r?\n)|\r/.match s }
    string = string.join "\n"

    # get rid of any extra columns
    string.gsub!(/,,*$/, '')

    # import data by row
    CSV.parse(string, headers: true) do |row|
      object_hash = row.to_hash.symbolize_keys

      # make all nil values blank
      object_hash.keys.each do |key|
        object_hash[key] = '' if object_hash[key].nil?
      end
      imported_objects << object_hash
    end
    # return array of imported objects
    imported_objects
  end

  # The main import method. Pass in the array of imported objects from
  # csv_import, the overwrite boolean, and the user type. The safe defaults
  # are specified here. It first tries to save or update the user with the
  # data specified in the csv. If that fails, it tries ldap. If both fail,
  # the user is returned as part of the array of failures.
  def import_users(array_of_user_data, overwrite = false, user_type = 'normal')
    @array_of_success = [] # will contain user-objects
    @array_of_fail = [] # will contain user_data hashes and error messages
    @overwrite = overwrite

    array_of_user_data.each do |user_data|
      user_data[:role] = user_type
      user_data[:csv_import] = true
      next if attempt_save_with_csv_data?(user_data)
      if env?('USE_LDAP')
        attempt_save_with_ldap(user_data)
      else
        @array_of_fail << [user_data, 'Invalid user parameters.']
      end
    end

    # rubocop:disable UselessAssignment
    hash_of_statuses = { success: @array_of_success, fail: @array_of_fail }
    # rubocop:enable UselessAssignment
  end

  # attempts to import with LDAP, returns nil if the login is not found,
  # otherwise it replaces the keys in the data hash with the ldap data.
  def import_with_ldap(user_data)
    # use username if using cas, email otherwise
    ldap_param = user_data[env?('CAS_AUTH') ? :username : :email]

    # check LDAP for missing data
    ldap_user_hash = User.search_ldap(ldap_param)

    # if nothing found via LDAP
    return if ldap_user_hash.nil?

    # fill-in missing key-values with LDAP data
    user_data.keys.each do |key|
      if user_data[key].blank? && !ldap_user_hash[key].blank?
        user_data[key] = ldap_user_hash[key]
      end
    end
    user_data
  end

  # tries to save using only the csv data. This method will return
  # false if the data specified in the csv is invalid on the user model.
  def attempt_save_with_csv_data?(user_data)
    if env?('CAS_AUTH')
      # set the cas login
      user_data[:cas_login] = user_data[:username]
    else
      # set the username
      user_data[:username] = user_data[:email]
    end

    user = set_or_create_user_for_import(user_data)

    user.update_attributes(user_data)
    # if the updated or new user is valid, save to database and add to array
    # of successful imports
    return false unless user.valid?
    user.save
    @array_of_success << user
    true
  end

  # attempts to save a user with ldap lookup
  def attempt_save_with_ldap(user_data)
    ldap_hash = import_with_ldap(user_data)
    if ldap_hash
      user_data = ldap_hash
    else
      @array_of_fail << [user_data,
                         'Incomplete user information. Unable to find user '\
                         'in online directory (LDAP).']
      return
    end

    user = set_or_create_user_for_import(user_data)

    if user.valid?
      user.save
      @array_of_success << user
    else
      @array_of_fail << [user_data,
                         user.errors.full_messages.to_sentence.capitalize\
                         + '.']
    end
    nil
  end

  # sets the user based on the overwrite parameter
  # rubocop:disable AccessorMethodName
  def set_or_create_user_for_import(user_data)
    # set the user and attempt to save with given data
    user = if @overwrite &&
              !User.where('username = ?', user_data[:username]).empty?
             User.where('username = ?', user_data[:username]).first
           else
             User.new(user_data)
           end
    user
  end
  # rubocop:enable AccessorMethodName
end
