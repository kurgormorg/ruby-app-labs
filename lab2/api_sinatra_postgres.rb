require 'bundler/setup'
require 'sequel'
require 'sequel/extensions/seed'
require 'pg'
require 'json'
require 'multi_json'
require 'sinatra'
require_relative 'config/database'

set :server, :puma

%w[controllers models routes].each do |dir|
  Dir.glob(File.join(__dir__, dir, '*.rb')).sort.each { |file| require file }
end
