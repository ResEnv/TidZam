
class controller
	me = this

	constructor: ->
		me.serv 		= new (require('./server.js')).Server (1234)
		me.serv.start()

		me.streamer 	= new (require('./streamer.js')).Streamer (state)->
			if me.socket
				me.socket.emit 'sys', JSON.stringify( {sys: {state:state, sample_count:me.streamer.getSampleCount()} } )

		me.classifier  = new (require('./classifier.js')).Classifier me.streamer.getSampleFile(), (code, data) ->
			if me.socket
				me.socket.emit 'data', data
		me.classifier.start()

		me.serv.setSampleFile(me.streamer.getSampleFile())

		me.serv.io.on 'connection', (socket) ->
			me.socket = socket

			setTimeout (->
				me.socket.emit 'data', JSON.stringify(me.classifier.getConf())
				), 5000

			socket.on 'sys', (msg) ->
				console.log 'sys event: ' + msg.toString()
				try
					req = JSON.parse(msg)
					sys = req.sys
					if !sys
						throw "Not a sys object"
				catch err
						console.log "WARNING: Socket error for sys event: " + msg
						return

				switch
					when sys.control then me.streamer.control(sys.control)
					when sys.url		 then me.streamer.url = sys.url








new controller()


###
			console.log " plop "  + JSON.stringify(me.classifier.getConf()

#	socket.emit 'data', JSON.stringify(me.classifier.getConf())



stream.startBuffering "./stream.ogg", (code, data) ->
  if !code || 0
    stream.convertOggtoWav data, (code, data) ->
      if !code || 0
        for i in [0...10]
          stream.nextSample (code, data) ->
            console.log data

      else console.log "Wav conversion error: " + data
  else console.log "Buffering error: " + data
###
