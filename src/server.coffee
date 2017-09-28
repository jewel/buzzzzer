http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'
sys = require 'sys'

send404 = (res) ->
  res.writeHead(404)
  res.write('404')
  res.end()
  res

values = (obj) ->
  arr = []
  for k,v of obj
    arr.push v
  arr

server = http.createServer (req,res) ->
  path = url.parse(req.url).pathname
  console.log( path )
  path = '/index.html' if path == '/'
  fs.readFile "#{__dirname}/../public/" + path, (err,data) ->
    return send404 res if err
    ext = path.substr path.lastIndexOf( "." ) + 1
    content_type = switch ext
      when 'wav' then 'audio/wav'
      when 'js' then 'text/javascript'
      when 'css' then 'text/css'
      when 'html' then 'text/html'
      else
        console.log "Unknown content type: #{ext}"
    res.writeHead 200, 'Content-Type': content_type
    res.write data, 'utf8'
    res.end()

port = 4101
server.listen port

console.log "Server running on http://localhost:#{port}"

io = io.listen(server)
io.set 'log level', 2

current = null
clients = {}
names = {}

rand = (max) ->
  Math.floor Math.random() * max

send_updates = (sound=null) ->
  for i, c of clients
    c.emit 'update',
      names: values(names)
      current: current
      sound: sound

io.sockets.on 'connection', (client) ->
  console.log 'new client'
  clients[client.id] = client

  client.on 'update', (msg) ->
    names[client.id] = msg.name || "Anonymous Coward"
    sound = null
    if msg.tap
      if msg.name == 'master'
        if current
          sound = "clear#{rand(3)}"
        current = null
      else if !current
        if current != msg.name
          sound = "tap#{rand(3)}"
        current = msg.name

    send_updates sound

  client.on 'error', ->
    console.log( "error" )
    delete clients[client.id]
    delete names[client.id]
    send_updates()

  client.on 'disconnect', ->
    delete clients[client.id]
    delete names[client.id]
    send_updates()
