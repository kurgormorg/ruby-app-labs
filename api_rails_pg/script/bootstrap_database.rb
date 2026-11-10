require 'fileutils'
require 'pg'

# Отдельный локальный PostgreSQL для лабораторной.
Dir.chdir(File.expand_path('..', __dir__))
data = File.expand_path('.local-postgres')
port = ENV.fetch('PGPORT', '5434')
unless File.exist?(File.join(data, 'PG_VERSION'))
  FileUtils.mkdir_p('tmp')
  password_file = File.expand_path('tmp/postgres-password')
  File.write(password_file, "lab_postgres\n")
  begin
    abort 'initdb failed' unless system('initdb', '-D', data, '-U', 'postgres', '-A', 'scram-sha-256', '--pwfile', password_file, '--encoding=UTF8', '--locale=C')
  ensure
    File.delete(password_file) if File.exist?(password_file)
  end
end
unless system('pg_ctl', '-D', data, 'status', out: File::NULL, err: File::NULL)
  abort 'pg_ctl failed' unless system('pg_ctl', '-D', data, '-l', File.expand_path('log/postgres.log'), '-o', "-p #{Integer(port)} -h 127.0.0.1", '-w', 'start')
end
connection = PG.connect(host: '127.0.0.1', port: port, dbname: 'postgres', user: 'postgres', password: 'lab_postgres')
unless connection.exec("SELECT 1 FROM pg_roles WHERE rolname = 'api_admin'").ntuples.positive?
  connection.exec("CREATE ROLE api_admin WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'api_admin'")
end
%w[development test production].each do |environment|
  name = "api_rails_pg_#{environment}"
  next if connection.exec_params('SELECT 1 FROM pg_database WHERE datname = $1', [name]).ntuples.positive?
  connection.exec("CREATE DATABASE #{connection.quote_ident(name)} OWNER api_admin")
end
connection.close
puts "PostgreSQL ready on 127.0.0.1:#{port}"
