require 'rubygems'
require 'sinatra'
require 'mongo'
require 'haml'

def get_last_state(host)
  check = @db.collection('checks').find({ 'host_id' => host['_id'] }).sort(['timestamp', 'descending']).first
  return ['-', '-'] unless check
  status = check['status'] ? 'ok' : 'fail'
  [status, check['timestamp']]
end

def human_time(timestamp)
  Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S')
end

def get_checks_result(host)
  checks = {
    :total => @db.collection('checks').find({ 'host_id' => host['_id'] }).count,
    :failed => @db.collection('checks').find({ 'host_id' => host['_id'], 'status' => false }).count
  }
  checks[:uptime] = (checks[:total] - checks[:failed]) * 100 / checks[:total]
  checks
end

before do
  @db = Mongo::Connection.new.db('checks')
end

get '/' do
  @hosts = []
  @db.collection('hosts').find.each do |host|
    status, check_timestamp = get_last_state(host)
    @hosts << { 
      :ip => host['ip'],
      :host => host['host'],
      :status => status,
      :uptime => get_checks_result(host)[:uptime],
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
  @checks = get_checks_result(@host)
  haml :details, :format => :html5
end
