$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path -LiteralPath '.idea/dataSources.xml')) {
        New-Item -ItemType Directory -Path '.idea' -Force | Out-Null
        Copy-Item -LiteralPath 'config/rubymine/dataSources.xml' -Destination '.idea/dataSources.xml'
    }
    & bundle check
    if ($LASTEXITCODE -ne 0) {
        & bundle install
        if ($LASTEXITCODE -ne 0) { throw 'bundle install failed' }
    }
    if (-not (Test-Path -LiteralPath '.local-postgres/PG_VERSION')) {
        & initdb -D .local-postgres -U postgres --auth=trust --encoding=UTF8 --locale=C
        if ($LASTEXITCODE -ne 0) { throw 'initdb failed' }
    }
    & pg_ctl -D .local-postgres status
    if ($LASTEXITCODE -ne 0) {
        & pg_ctl -D .local-postgres -l log/postgresql.log -o '-h 127.0.0.1 -p 5433' -w start
        if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL start failed' }
    }
    & ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'script/bootstrap_database.rb')"
    if ($LASTEXITCODE -ne 0) { throw 'Database setup failed' }
    & ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'bin/rails')" -- db:migrate db:seed db:test:prepare
    if ($LASTEXITCODE -ne 0) { throw 'Migrations failed' }
} finally {
    Pop-Location
}
