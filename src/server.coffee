class Server
  me = this
  constructor: (port) ->
    me.port         = @port           = port = port
    me.sample_file  = @sample_file    = "tmp/sample.wav"
    @app = app       = require("express")()
    @server = server = require('http').Server(app)
    @io = io         = require('socket.io')(server);

    app.get "/", (req, res) ->
      res.end 'Hello ! Move to /client/index.html'

    app.get "/stream", (req,res) ->
      try
        res.sendFile me.sample_file, { root: __dirname + '/../' }
      catch err
        console.log "Error during reading of" + @sample_file

    app.get /^(.+)$/, (req,res) ->
        res.sendfile  __dirname + req.params[0];

    io.on 'connection', (socket) ->
      console.log "connection : "
#      setTimeout (->io.emit 'data', 'test'),1000

      socket.on 'chat message', (msg) ->
        io.emit 'chat message', msg

  setSampleFile: (file) ->
    @sample_file = file

  start:  ->
    port = @port
    @server.listen @port, ->
      console.log 'Started on port ' + port

exports.Server = Server
