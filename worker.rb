#!/usr/bin/env ruby
require 'rubygems'
require 'socket'
require 'json'

server = TCPServer.new 6000

loop do
  Thread.start(server.accept) do |client|
    begin
      request = JSON.parse(client.gets)
      ip = request['ip']
      raise 'Invalid IP' unless ip.match(/\A(\d+\.?){4}\z/)

      `ping -W 2 -c 1 #{ip}`
      result = $?.success? ? 'ok' : 'fail'

      client.puts({ 'result' => result }.to_json)
      client.close
    rescue Exception => e
      client.puts({ 'error' => e.message }.to_json)
      client.close
    end
  end
end
