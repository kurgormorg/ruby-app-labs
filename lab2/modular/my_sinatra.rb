require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/namespace'

module MyAppModule
  class App < Sinatra::Base
    register Sinatra::Namespace
    set :server, :puma

    get '/' do
      'Hello My Sinatra - Easy and Wide world!'
    end

    get '/hello/:name' do |name|
      "Sinatra приветствует тебя, #{name}!"
    end

    get '/redirect' do
      redirect to('/hello/World')
    end

    get %r{.*/hello/([\w]+).*} do |name|
      "Hello, #{name}!"
    end

    get '/players/:sport_id' do
      params[:sport_id]
    end

    get '/players/*/:year' do
      "#{params[:splat]} #{params[:year]}"
    end

    get '/say/*/to/*' do
      params[:splat].join
    end

    get '/download/*.*' do |path, ext|
      [path, ext].inspect
    end

    get '/jobs.?:format?' do
      'Да, работает этот маршрут!'
    end

    namespace '/api/v1' do
      get '/*' do
        "I don't know what is the #{params[:splat]}. It's what you typed."
      end
    end

    get '/*' do
      "I don't know what is the #{params[:splat]}. It's what you typed."
    end

    run! if app_file == $PROGRAM_NAME
  end
end
