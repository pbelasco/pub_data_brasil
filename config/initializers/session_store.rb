# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_pdata_session',
  :secret      => 'cfd862efdf8798f7d9876fddaacbcbfbfccbaf3cbafcba3cfbafcbaf3bcfbf3bfbfa4b4bfbf6bf5abcf5a9b753c55bf35fb9ca753cfba753fcba573fcb9a75f5372'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
