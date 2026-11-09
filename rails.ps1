$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    & ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'bin/rails')" -- @args
    $railsExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $railsExitCode
