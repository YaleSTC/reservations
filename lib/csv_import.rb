module CsvImport
  # method used to convert a csv filepath to an array of objects specified by the file
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

  # The main import method. Pass in the array of imported objects from csv_import,
  # the overwrite boolean, and the user type. The safe defaults are specified here.
  # It first tries to save or update the user with the data specified in the csv. If that
  # fails, it tries ldap. If both fail, the user is returned as part of the array of failures.
  def import_users(array_of_user_data, overwrite=false, user_type='normal')

    @array_of_success = [] # will contain user-objects
    @array_of_fail = [] # will contain user_data hashes and error messages
    @overwrite = overwrite

    array_of_user_data.each do |user_data|
      user_data[:role] = user_type
      user_data[:csv_import] = true
      if attempt_save_with_csv_data?(user_data)
        next
      else
        attempt_save_with_ldap(user_data)
        next
      end
    end

    hash_of_statuses = {:success => @array_of_success, :fail => @array_of_fail}
  end

  # attempts to import with LDAP, returns nil if the login is not found, otherwise it
  # replaces the keys in the data hash with the ldap data.
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


  # tries to save using only the csv data. This method will return
  # false if the data specified in the csv is invalid on the user model.
  def attempt_save_with_csv_data?(user_data)
    user = set_or_create_user_for_import(user_data)

    user.update_attributes(user_data)
    # if the updated or new user is valid, save to database and add to array of successful imports
    if user.valid?
      user.save
      @array_of_success << user
      return true
    else
      return false
    end
  end

  # attempts to save a user with ldap lookup
  def attempt_save_with_ldap(user_data)
    ldap_hash = import_with_ldap(user_data)
    if ldap_hash
      user_data = ldap_hash
    else
      @array_of_fail << [user_data, 'Incomplete user information. Unable to find user in online directory (LDAP).']
      return
    end

    user = set_or_create_user_for_import(user_data)

    if user.valid?
      user.save
      @array_of_success << user
      return
    else
      @array_of_fail << [user_data, user.errors.full_messages.to_sentence.capitalize + '.']
      return
    end
  end

  # sets the user based on the overwrite parameter
  def set_or_create_user_for_import(user_data)
    # set the user and attempt to save with given data
    if @overwrite and (User.where("login = ?", user_data[:login]).size > 0)
      user = User.where("login = ?", user_data[:login]).first
    else
      user = User.new(user_data)
    end
    return user
  end
end