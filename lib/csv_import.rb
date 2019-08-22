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
      if ENV['USE_LDAP'].present? || ENV['USE_PEOPLE_API'].present?
        attempt_save_with_search(user_data)
      else
        @array_of_fail << [user_data, 'Invalid user parameters.']
      end
    end

    { success: @array_of_success, fail: @array_of_fail }
  end

  # attempts to import with LDAP or People, returns nil if the login is not
  # found, otherwise it replaces the keys in the data hash with the search data.
  def import_with_search(user_data)
    # use username if using cas, email otherwise
    search_param = user_data[:username]

    search_user_hash = User.search(login: search_param)

    return if search_user_hash.nil?

    # fill-in missing key-values with search data
    search_user_hash.keys.each do |key|
      user_data[key] = search_user_hash[key] if user_data[key].blank?
    end

    user_data
  end

  # tries to save using only the csv data. This method will return
  # false if the data specified in the csv is invalid on the user model.
  def attempt_save_with_csv_data?(user_data)
    if ENV['CAS_AUTH']
      # set the cas login
      user_data[:cas_login] = user_data[:username]
    elsif user_data[:username].blank?
      # set the username
      user_data[:username] = user_data[:email]
    end

    user = set_or_create_user_for_import(user_data)
    # Remove nil values to avoid failing validations - we this allows us to
    # update role of a bunch of users by passing in only their usernames
    # (instead of all of their user data).
    data_to_update = user_data.keep_if { |_, v| v.present? }
    user.update_attributes(data_to_update)

    # if the updated or new user is valid, save to database and add to array
    # of successful imports
    return false unless user.valid?
    user.save
    @array_of_success << user
    true
  end

  # attempts to save a user with search lookup
  def attempt_save_with_search(user_data)
    search_hash = import_with_search(user_data)
    if search_hash
      user_data = search_hash
    else
      @array_of_fail << [user_data,
                         'Incomplete user information. Unable to find user '\
                         'in online directory.']
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
