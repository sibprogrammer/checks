require 'rubygems'
require 'sinatra'
require 'mongo'
require 'haml'

def get_status(host_id)
  check = @db.collection('checks').find({ 'host_id' => host_id }).sort(['timestamp', 'descending']).first
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
      :ip => host['ip'],
      :host => host['host'],
      :status => status,
      :time => '-' == check_timestamp ? '-' : human_time(check_timestamp),
    }
  end

  haml :index, :format => :html5
end

get '/agents' do
  @agents = @db.collection('agents').find
  haml :agents, :format => :html5
end

get '/details' do
  @host = @db.collection('hosts').find_one({ 'ip' => params[:ip] })
  @checks = {
    :total => @db.collection('checks').find({ 'host_id' => @host['_id'] }).count,
    :failed => @db.collection('checks').find({ 'host_id' => @host['_id'], 'status' => false }).count
  }
  @checks[:uptime] = (@checks[:total] - @checks[:failed]) * 100 / @checks[:total]
  haml :details, :format => :html5
end
