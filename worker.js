#!/usr/bin/env node

var net = require('net');

net.createServer(function(socket) {
  console.log('Connected: ' + socket.remoteAddress + ':' + socket.remotePort);

  socket.on('data', function(data) {
    try {
      var request = JSON.parse(data);
    } catch(e) {
      console.log('Invalid request: ' + data);
      socket.end();
      return;
    }

    console.log('Request: ' + data.toString().trim());

    var ping = require("child_process").spawn("ping", ['-W', 2, '-c', 1, request.ip]);
    ping.on('exit', function(code) {
      var result = (0 == code) ? 'ok' : 'fail';
      socket.write(JSON.stringify({ 'result': result }));
      socket.end();
    });
  });

  socket.on('close', function(data) {
    console.log('Disconnected.');
  });
}).listen(6000);

console.log('Server started...');
