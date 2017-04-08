# frozen_string_literal: true
# Check for authentication method and copy data over if necessary (ENV variable
# to skip if necessary, skip if migrating from a pre-v4.1.0 DB or no table)
unless env?('SKIP_AUTH_INIT') || !User.table_exists? ||
       !User.column_names.include?('username')

  user = User.first

  # if we want to use CAS authentication and the username parameter doesn't
  # match the cas_login parameter, we need to copy that over
  if env?('CAS_AUTH') && user && (user.username != user.cas_login)
    # if there are any users that don't have cas_logins, we can't use CAS
    if User.where(cas_login: ['', nil]).count > 0
      raise 'There are users missing their CAS logins, you cannot use CAS '\
        'authentication.'
    else
      User.update_all 'username = cas_login'
    end
  # if we want to use password authentication all users can reset their
  # passwords so it doesn't matter if they already have them or not
  elsif env?('CAS_AUTH')
    User.update_all 'username = email'
  end
end
