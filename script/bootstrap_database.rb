require "pg"
require "yaml"
require "securerandom"
require "fileutils"

root = File.expand_path("..", __dir__)
secret_path = File.join(root, "config", "secrets.yml")
existing = File.exist?(secret_path) ? YAML.safe_load_file(secret_path) : {}
password = existing.dig("development", "database", "password") || SecureRandom.hex(24)
connection = PG.connect(host: "127.0.0.1", port: 5433,
  user: existing.empty? ? "postgres" : "messenger_admin",
  password: password, dbname: "postgres")
# Only change authentication in the isolated cluster belonging to this project.
cluster = File.join(root, ".local-postgres")
actual_cluster = connection.exec("SHOW data_directory").getvalue(0, 0)
# PostgreSQL on this Windows installation reports OS paths in Windows-1251.
def windows_path(value)
  value.valid_encoding? ? value : value.dup.force_encoding("Windows-1251").encode("UTF-8")
end
actual_cluster = windows_path(actual_cluster)
raise "Refusing to configure a different PostgreSQL cluster" unless File.realpath(actual_cluster).casecmp?(File.realpath(cluster))
connection.exec("SET password_encryption = 'scram-sha-256'")
unless connection.exec("SELECT 1 FROM pg_roles WHERE rolname = 'messenger_admin'").ntuples.positive?
  connection.exec("CREATE ROLE messenger_admin LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD #{connection.escape_literal(password)}")
end
connection.exec("ALTER ROLE messenger_admin PASSWORD #{connection.escape_literal(password)}")
admin_password = existing.dig("local_postgres_admin", "password") || SecureRandom.hex(24)
connection.exec("ALTER ROLE postgres PASSWORD #{connection.escape_literal(admin_password)}")
secrets = %w[development test production].to_h do |environment|
  [environment, { "database" => { "password" => password } }]
end
secrets["local_postgres_admin"] = { "password" => admin_password }
File.write(secret_path, secrets.to_yaml)
%w[development test production].each do |environment|
  database = "corporate_messenger_#{environment}"
  unless connection.exec_params("SELECT 1 FROM pg_database WHERE datname = $1", [database]).ntuples.positive?
    connection.exec("CREATE DATABASE #{connection.quote_ident(database)} OWNER messenger_admin")
  end
end
hba_path = windows_path(connection.exec("SHOW hba_file").getvalue(0, 0))
raise "Unexpected pg_hba.conf path" unless File.realpath(hba_path).casecmp?(File.realpath(File.join(cluster, "pg_hba.conf")))
hba = File.read(hba_path)
File.write(hba_path, hba.gsub(/^(?!\s*#)(.*\s)trust(\s*(?:#.*)?)$/, '\\1scram-sha-256\\2'))
connection.exec("SELECT pg_reload_conf()")
connection.close
PG.connect(host: "127.0.0.1", port: 5433, user: "messenger_admin", password: password, dbname: "postgres").close
puts "Local role and three databases are ready; SCRAM password authentication is enabled."
