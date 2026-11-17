$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    foreach ($mode in @('classic', 'modular', 'api')) {
        ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'script/check_routes.rb')" -- $mode
        if ($LASTEXITCODE -ne 0) { throw "Check failed: $mode" }
    }
} finally {
    Pop-Location
}
