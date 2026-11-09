require "pg"
require "yaml"
require "securerandom"
require "fileutils"

root = File.expand_path("..", __dir__)
secret_path = File.join(root, "config", "secrets.yml")
existing = File.exist?(secret_path) ? YAML.safe_load_file(secret_path) : {}
password = existing.dig("development", "database", "password") || SecureRandom.hex(24)
connection = PG.connect(host: "127.0.0.1", port: 5433, user: "postgres", dbname: "postgres")
unless connection.exec("SELECT 1 FROM pg_roles WHERE rolname = 'messenger_admin'").ntuples.positive?
  connection.exec("CREATE ROLE messenger_admin LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD #{connection.escape_literal(password)}")
end
secrets = %w[development test production].to_h do |environment|
  [environment, { "database" => { "password" => password } }]
end
File.write(secret_path, secrets.to_yaml)
%w[development test production].each do |environment|
  database = "corporate_messenger_#{environment}"
  unless connection.exec_params("SELECT 1 FROM pg_database WHERE datname = $1", [database]).ntuples.positive?
    connection.exec("CREATE DATABASE #{connection.quote_ident(database)} OWNER messenger_admin")
  end
end
connection.close
puts "Local role and three databases are ready; password is in ignored config/secrets.yml."
