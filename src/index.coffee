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

				if sys.training?.build then 	me.dataset.buildClassifier sys.training.build,  sys.training.filter_low, sys.training.filter_high,  sys.training.structure, sys.training.epoch, sys.training.learning_rate, (code,data) ->
					if 			code == 0
						socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'done',data:data}}}
						me.classifier.getAvailableClassifiers (code,data) ->
							if !code then me.socket.emit 'sys', JSON.stringify {sys:{classifier:{list: data }}}
							else console.log "WARNING Error controller: " + data
					else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'running',data:data}}}
					else socket.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'failed',out:data}}}

				if sys.training?.do == 'next' then me.dataset.getNextTraining sys.training.show, sys.training.filter_low, sys.training.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{training:{show:data}}}

				if sys.training?.do == 'prev' then me.dataset.getPrevTraining sys.training.show, sys.training.filter_low, sys.training.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{training:{show:data}}}


				# DATASET EVENTS
				if sys.dataset?.list? then me.dataset.getDatasets (code,data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{dataset:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.dataset?.build then 	me.dataset.buildDataset sys.dataset?.build, (code,data) ->
					if 			code == 0
						socket.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'done',data:data}}}
						me.dataset.getTrainingSets (code,data) ->
							if !code then me.socket.emit 'sys', JSON.stringify {sys:{training:{list: data }}}
							else console.log "WARNING Error controller: " + data

					else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'running',data:data}}}
					else socket.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'failed',out:data}}}

				if sys.dataset?.delete then 	me.dataset.deleteSample sys.records?.delete, (code,data) ->
					if !code then	me.dataset.getPrevSample sys.dataset?.delete, (code,data) ->
							socket.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}
					else console.log "WARNING Delete sample: " + sys.dataset?.delete + " failed. \n("+data+")"

				if sys.dataset?.do == 'next' then me.dataset.getNextSample sys.dataset.show, sys.dataset.filter_low, sys.dataset.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}

				if sys.dataset?.do == 'prev' then me.dataset.getPrevSample sys.dataset.show, sys.dataset.filter_low, sys.dataset.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}

				# DATABASE RECORD EVENTS
				if sys.records?.list?	then me.dataset.getDatabases (code, data) ->
					if !code then me.socket.emit 'sys', JSON.stringify {sys:{records:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.records?.build
					me.dataset.buildDatabase sys.records?.build, (code,data) ->
						console.log data
						if 			code == 0
							socket.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'done',data:data}}}
							me.dataset.getDatasets (code,data) ->
								if !code then me.socket.emit 'sys', JSON.stringify {sys:{dataset:{list: data }}}
								else console.log "WARNING Error controller: " + data
						else if code == 1  then	socket.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'running',data:data}}}
						else socket.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'failed',out:data}}}

				if sys.records?.delete then 	me.dataset.deleteRecord sys.records?.delete, (code,data) ->
					if code then	console.log "WARNING Delete sample: " + sys.records?.delete + " failed. \n("+data+")"

				if sys.records?.do == 'next' then me.dataset.getNextRecord sys.records.show, sys.records.filter_low, sys.records.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{records:{show:data}}}

				if sys.records?.do == 'prev' then me.dataset.getPrevRecord sys.records.show, sys.records.filter_low, sys.records.filter_high, (code,data) ->
					socket.emit 'sys', JSON.stringify {sys:{records:{show:data}}}

new controller()
