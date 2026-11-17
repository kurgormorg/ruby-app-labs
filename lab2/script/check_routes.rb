require 'bundler/setup'
require 'rack/mock'

mode = ARGV.fetch(0, 'modular')
root = File.expand_path('..', __dir__)
file = mode == 'api' ? 'api_sinatra_postgres.rb' : "#{mode}/my_sinatra.rb"
require File.join(root, file)
app = mode == 'modular' ? MyAppModule::App : Sinatra::Application
app.set :run, false
request = Rack::MockRequest.new(app)

expected = if mode == 'api'
  { '/' => "Hi! I am api_sinatra_postgres!\n\n" }
else
  {
    '/' => 'Hello My Sinatra - Easy and Wide world!',
    '/hello/Peter' => 'Sinatra приветствует тебя, Peter!',
    '/api/v1/friends' => 'I don\'t know what is the ["friends"]. It\'s what you typed.',
    '/friends' => 'I don\'t know what is the ["friends"]. It\'s what you typed.'
  }
end

if mode == 'modular'
  expected.merge!({
    '/players/football' => 'football',
    '/players/performances/2016' => '["performances"] 2016',
    '/meta/hello/12345/world' => 'Hello, 12345!',
    '/meta/hello/world' => 'Hello, world!',
    '/hello/world/1234' => 'Hello, world!',
    '/say/12345*/to/09876*' => '12345*09876*',
    '/download/path/to/file.xml' => '["path/to/file", "xml"]',
    '/jobs' => 'Да, работает этот маршрут!',
    '/jobs.json' => 'Да, работает этот маршрут!',
    '/jobs.xml' => 'Да, работает этот маршрут!'
  })
  response = request.get('/redirect', 'HTTP_HOST' => 'localhost')
  raise 'Redirect failed' unless response.status == 302 && URI(response['location']).path == '/hello/World'
  response = request.get('/hello/World', 'HTTP_HOST' => 'localhost')
  raise 'Redirect target failed' unless response.body == 'Sinatra приветствует тебя, World!'
end

expected.each do |path, body|
  response = request.get(path, 'HTTP_HOST' => 'localhost')
  raise "#{path}: #{response.status} #{response.body}" unless response.status == 200 && response.body == body
end
raise 'PostgreSQL connection failed' if mode == 'api' && !DB.test_connection
puts "#{mode}: #{expected.size} routes OK"
