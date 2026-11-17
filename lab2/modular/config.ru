require_relative 'my_sinatra'

app = Rack::Builder.app do
  run MyAppModule::App
end

run app
