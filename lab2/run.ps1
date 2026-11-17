param(
    [ValidateSet('api', 'classic', 'classic-rack', 'modular', 'modular-rack')]
    [string]$Mode = 'api'
)

Push-Location $PSScriptRoot
try {
    switch ($Mode) {
        'classic' { ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'classic/my_sinatra.rb'); Sinatra::Application.run!" }
        'modular' { ruby -E UTF-8:UTF-8 -e "load File.join(Dir.pwd, 'modular/my_sinatra.rb'); MyAppModule::App.run!" }
        default {
            $configFile = switch ($Mode) {
                'classic-rack' { 'classic/config.ru' }
                'modular-rack' { 'modular/config.ru' }
                default { 'config.ru' }
            }
            bundle exec rackup -s puma -o 127.0.0.1 -p 4567 $configFile
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "Application exited with code $LASTEXITCODE" }
} finally {
    Pop-Location
}
