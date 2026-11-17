require 'dotenv/load'
require 'sequel'
require 'pg'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://api_admin:api_admin@127.0.0.1:5434/api_sinatra_pg_development'))
