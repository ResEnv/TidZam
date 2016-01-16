class controller
	me = this

	constructor: ->

		me.dataset    = new (require('./dataset.js')).Dataset
		me.stream    = new (require('./stream.js')).Stream

		me.serv 		= new (require('./server.js')).Server (1234)
		me.serv.start()

		me.streamer 	= new (require('./streamer.js')).Streamer (state)->
			if me.socket
				me.socket.emit 'sys', JSON.stringify( {sys: {state:state, sample_count:me.streamer.getSampleCount()} } )

		me.classifier  = new (require('./classifier.js')).Classifier me.streamer.getSampleFile(), (code, data) ->
			if me.socket
				me.socket.emit 'data', data
		me.classifier.start()

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
						console.log "WARNING: Socket error for sys event: " + err + " "+ msg
						return

				# Control interface between streamer and player
				if sys.control then me.streamer.control(sys.control)

				if sys.url		 then me.streamer.url = me.stream.getStreamPath() + sys.url

				if sys.streams? then me.stream.getStreams (code, data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{streams: data }}
					else console.log "WARNING Error controller: " + data

				if sys.sample && sys.classe then me.dataset.addCurrent sys.sample, sys.classe, me.streamer.getSampleFile(), (code, data) ->
						if !code then console.log 'Added sample ' + data
						else console.log 'Error adding sample: ' + data

				if sys.databases?.list?	then me.dataset.getDatabases (code, data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{databases:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.databases?.build then 	me.dataset.buildDatabase sys.databases?.build, (code,data) ->
					if !code then console.log "Building dataset " + sys.databases?.build + " done."
					else console.log "WARNING Building dataset: " + sys.databases?.build + " failed. \n("+data+")"

				if sys.databases?.delete then 	me.dataset.deleteSample sys.databases?.delete, (code,data) ->
					if !code
						console.log "Delete sample " + sys.databases?.delete + " done."
						me.dataset.getPrevSample sys.databases?.delete, (code,data) ->
							socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}

					else console.log "WARNING Delete sample: " + sys.databases?.delete + " failed. \n("+data+")"

				if sys.databases?.do == 'next' && sys.databases?.show then me.dataset.getNextSample sys.databases.show, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}

				if sys.databases?.do == 'prev' && sys.databases?.show then me.dataset.getPrevSample sys.databases.show, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}

new controller()
