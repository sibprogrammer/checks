#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'socket'
require 'json'

def log(message)
  puts message
end

def ping(host)
  log "ping #{host}"
  socket = TCPSocket.open('127.0.0.1', 6000)
  socket.print({ :ip => host }.to_json)
  response = JSON.parse(socket.read)
  'ok' == response['result']
end

db = Mongo::Connection.new.db('checks')

loop do
  db.collection('hosts').find.each do |host|
    result = ping(host['host'])
    log "ping result: #{result}"
    db.collection('checks').insert({
      :host_id => host['_id'],
      :status => result,
      :timestamp => Time.now.to_i,
    })
  end

  sleep 10
end
