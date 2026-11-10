Push-Location $PSScriptRoot
try {
    ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'bin/rails')" -- @args
    if ($LASTEXITCODE -ne 0) { throw "Rails exited with code $LASTEXITCODE" }
} finally {
    Pop-Location
}
