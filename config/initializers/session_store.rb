# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_dimes_session',
  :secret      => '039b5802f1981c30515a626a77719dfbc4dea93af25056f83baaaba22f05f44e8e598450abe53abd9ef505b8ef3395fadfafadfc267a515d1288a5c467874782'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
