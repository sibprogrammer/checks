#!/usr/bin/env ruby

require 'rubygems'
require 'socket'
require 'json'

server = TCPServer.new 6000

loop do
  Thread.start(server.accept) do |client|
    puts "client connected"
    while (data = client.gets and data.chomp != 'stop') do
      puts "request #{data}"
      request = JSON.parse(data.chomp)
      ip = request['ip']
      break unless ip.match(/\A(\d+\.?){4}\z/)
      `ping -W 2 -c 1 #{ip}`
      result = $?.success? ? 'ok' : 'fail'
      client.puts({ 'result' => result }.to_json)
      puts "sent #{result}"
    end
    client.close
    puts "close connection"
  end
end
