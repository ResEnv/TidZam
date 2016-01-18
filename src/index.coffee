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
		me.classifier.init()

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

				# RECOGNITION ENGINE INTERFACE EVENTS


				if sys.control then me.streamer.control(sys.control)
				if sys.url		 then me.streamer.url = me.stream.getStreamPath() + sys.url

				if sys.streams? then me.stream.getStreams (code, data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{streams: data }}
					else console.log "WARNING Error controller: " + data

				if sys.sample && sys.classe then me.dataset.addCurrent sys.sample, sys.classe, me.streamer.getSampleFile(), (code, data) ->
						if !code then console.log 'Added sample ' + data
						else console.log 'Error adding sample: ' + data

				# CLASSIFIER EVENT

				if sys.classifier?.toggle  then me.classifier.toggleClassifier sys.classifier?.toggle, (code, data) ->
						if !code then console.log 'Toggle of classifier ' + data + ' done.'
						else console.log 'Toggle of classifier ' + sys.classifier?.toggle + ' failed.' + data

				if sys.classifier?.list? then me.classifier.getAvailableClassifiers (code,data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{classifier:{list: data }}}
					else console.log "WARNING Error controller: " + data

				# TRAINING EVENTS
				if sys.training?.list? then me.dataset.getTrainingSets (code,data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{training:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.training?.build then 	me.dataset.buildClassifier sys.training.build, (code,data) ->
					if 			code == 0
						socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'done',data:data}}}
						me.classifier.getAvailableClassifiers (code,data) ->
							if !code then me.socket.emit 'sys', JSON.stringify {sys:{classifier:{list: data }}}
							else console.log "WARNING Error controller: " + data
					else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'running',data:data}}}
					else socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'failed',out:data}}}

				# DATASET EVENTS
				if sys.datasets?.list? then me.dataset.getDatasets (code,data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{datasets:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.datasets?.build then 	me.dataset.buildDataset sys.datasets?.build, (code,data) ->
					if 			code == 0	 then	socket.emit 'sys', JSON.stringify {sys:{datasets:{build:sys.datasets.build, status:'done',data:data}}}
					else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{datasets:{build:sys.datasets.build, status:'running',data:data}}}
					else socket.emit 'sys', JSON.stringify {sys:{datasets:{build:sys.datasets.build, status:'failed',out:data}}}

				# DATABASE RECORD EVENTS
				if sys.databases?.list?	then me.dataset.getDatabases (code, data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{databases:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.databases?.build then 	me.dataset.buildDatabase sys.databases?.build, (code,data) ->
					if 			code == 0	 then	socket.emit 'sys', JSON.stringify {sys:{databases:{build:sys.databases.build, status:'done',data:data}}}
					else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{databases:{build:sys.databases.build, status:'running',data:data}}}
					else socket.emit 'sys', JSON.stringify {sys:{databases:{build:sys.databases.build, status:'failed',out:data}}}

				if sys.databases?.delete then 	me.dataset.deleteSample sys.databases?.delete, (code,data) ->
					if !code then	me.dataset.getPrevSample sys.databases?.delete, (code,data) ->
							socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}
					else console.log "WARNING Delete sample: " + sys.databases?.delete + " failed. \n("+data+")"

				if sys.databases?.do == 'next' && sys.databases?.show then me.dataset.getNextSample sys.databases.show, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}

				if sys.databases?.do == 'prev' && sys.databases?.show then me.dataset.getPrevSample sys.databases.show, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{databases:{show:data}}}

new controller()
