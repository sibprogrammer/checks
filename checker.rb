#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'socket'
require 'json'

def log(message)
  puts message
end

def ping(agent_socket, host)
  log "ping #{host}"
  agent_socket.puts({ :ip => host }.to_json)
  response = JSON.parse(agent_socket.gets)
  'ok' == response['result']
end

def get_sockets(agents)
  sockets = []
  agents.each do |agent|
    begin
      socket = TCPSocket.open(agent['ip'], 6000)
      sockets << socket
    rescue
    end
  end
  sockets
end

db = Mongo::Connection.new.db('checks')
count = 0
sockets = []

loop do
  sockets = get_sockets(db.collection('agents').find) if 0 == count

  sockets.each do |socket|
    db.collection('hosts').find.each do |host|
      begin
        log "agent: #{socket.peeraddr.last}"
        result = ping(socket, host['ip'])
        log "ping result: #{result}"
        db.collection('checks').insert({
          :host_id => host['_id'],
          :status => result,
          :timestamp => Time.now.to_i,
        })
      rescue Exception => e
        log "Error: #{e.message}"
      end
    end
  end

  sleep 10
  count += 1

  if count > 100
    log "close old connections"
    sockets.each{ |socket| socket.close }
    count = 0
  end
end
