require 'rubygems'
require 'sinatra'
require 'mongo'
require 'haml'

def get_status(host_id)
  check = @db.collection('checks').find_one('host_id' => host_id)
  return ['-', '-'] unless check
  status = check['status'] ? 'ok' : 'fail'
  [status, check['timestamp']]
end

def human_time(timestamp)
  Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S')
end

before do
  @db = Mongo::Connection.new.db('checks')
end

get '/' do
  @hosts = []
  @db.collection('hosts').find.each do |host|
    status, check_timestamp = get_status(host['_id'])
    @hosts << { 
      :host => host['host'],
      :status => status,
      :time => human_time(check_timestamp),
    }
  end

  haml :index, :format => :html5
end

