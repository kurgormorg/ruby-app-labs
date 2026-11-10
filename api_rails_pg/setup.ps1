$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    bundle install --local --quiet
    if ($LASTEXITCODE -ne 0) { throw 'bundle install failed' }
    if (!(Test-Path config/secrets.yml)) { Copy-Item config/secrets.yml.example config/secrets.yml }
    ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'script/bootstrap_database.rb')"
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL setup failed' }
    ./rails.ps1 db:migrate db:seed
    ./rails.ps1 db:migrate RAILS_ENV=test
    $previousPassword = $env:PGPASSWORD
    try {
        $env:PGPASSWORD = 'api_admin'
        ./rails.ps1 db:migrate RAILS_ENV=production
    } finally {
        $env:PGPASSWORD = $previousPassword
    }
} finally {
    Pop-Location
}
