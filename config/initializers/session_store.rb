# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_reservations_session',
  :secret      => 'd0cee142ede17b58a5da4f874f9f70e18f715ba6c1a67e33cd8512b71b2efd2fd67f8516966d778a63933d8f04220bfd263a9619a9e84c8cba39adddea69058b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
