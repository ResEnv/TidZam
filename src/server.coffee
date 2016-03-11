class Server
  me = this
  constructor: (port) ->
    me.port               = @port                = port = port
    me.sample_file        = @sample_file         = "tmp/sample.wav"
    me.fft_file           = @fft_file            = "tmp/fft.png"
    me.fft__databasefile  = @fft__databasefile   = "tmp/database-fft.png"

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

    app.get "/fft", (req,res) ->
      try
        res.sendFile me.fft_file, { root: __dirname + '/../' }
      catch err
        console.log "Error during reading of" + me.fft_file

    app.get "/record-fft", (req,res) ->
      try
        res.sendFile me.fft__databasefile, { root: __dirname + '/../' }
      catch err
        console.log "Error during reading of" + me.fft__databasefile

    app.get "/data/*", (req,res) ->
        res.sendfile 'data/' + req.params[0], { root: __dirname + '/../' }

    app.get "/client/*", (req,res) ->
        res.sendfile  req.params[0], { root: __dirname + '/../client/' }

  setSampleFile: (file) ->
    @sample_file = file

  start:  ->
    port = @port
    @server.listen @port, ->
      console.log 'Started on port ' + port

exports.Server = Server
