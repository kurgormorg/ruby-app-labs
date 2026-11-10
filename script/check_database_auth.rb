require "pg"
require "yaml"
secrets = YAML.safe_load_file(File.join(Dir.pwd, "config/secrets.yml"))
password = secrets.fetch("development").fetch("database").fetch("password")
options = { host: "127.0.0.1", port: 5433, user: "messenger_admin", dbname: "corporate_messenger_development", connect_timeout: 3 }
connection = PG.connect(**options, password: password)
raise "Authentication rules contain errors" unless connection.exec("SELECT 1 FROM pg_hba_file_rules WHERE error IS NOT NULL").ntuples.zero?
puts "Correct password: connection accepted."
connection.close
begin
  PG.connect(**options, password: "intentionally-wrong-password").close
rescue PG::ConnectionBad
  puts "Wrong password: connection rejected."
else
  abort "ERROR: PostgreSQL accepted a wrong password."
end
