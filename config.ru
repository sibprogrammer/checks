require 'index'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file, 'index.rb'
disable :run

log = File.new("log/sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

run Sinatra::Application
