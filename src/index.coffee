rmdir 		= require('rimraf')
spawn 		= require('child_process').spawn
optparse  	= require 'optparse'
ncp   		= require('ncp').ncp;

class controller
	me = this

	constructor: (port = 1234, source_url = '', chainAPI_url = '', chainAPI_site = '') ->
		me.port = port;
		me.chainAPI_url = chainAPI_url;
		me.chainAPI_site = chainAPI_site;

		me.dataset    = new (require('./dataset.js')).Dataset

		me.serv 		= new (require('./server.js')).Server (me.port)
		me.serv.start()

		me.streamer 	= new (require('./streamer.js')).Streamer (state)->
			if me.socket
				me.serv.io.sockets.emit 'sys', JSON.stringify( {sys: {state:state, sample_count:me.streamer.getSampleCount(), url: me.streamer.url} } )
		me.streamer.url = source_url
		me.streamer.loading()
		me.streamer.play()

		me.classifier  = new (require('./classifier.js')).Classifier me.streamer.getSampleFile(), (code, data) ->
			if me.socket
				me.serv.io.sockets.emit 'data', data
		me.classifier.init()

		if me.chainAPI_url.length > 0
			chainAPI = new (require('./chainAPI.js')).chainAPI(me.port, me.chainAPI_url, me.chainAPI_site)

		me.serv.io.on 'connection', (socket) ->
			me.socket = socket
			setTimeout (->
				me.serv.io.sockets.emit 'data', JSON.stringify(me.classifier.getConf())
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

				# Data System Reinitialization !! WARNING DELETE ALL DATA
				if sys.init?
					rmdir './data/processed_records/*', ->
						rmdir './data/database/*', ->
							rmdir './data/dataset/*', ->
								rmdir './data/training/*', ->
									rmdir './data/classifiers/*', ->
										# Put default classifier Nothing and its dataset
										ncp "./Nothing/", "./data/classifiers/", ->
											ncp "./Nothing/Nothing.dat", "./data/dataset/Nothing.dat", (err) ->
												console.log "System cleaned and ready."+ err

				# RECOGNITION ENGINE INTERFACE EVENTS
				if sys.control then me.streamer.control(sys.control)
				if sys.url		 then me.streamer.url = sys.url

				if sys.streams? then me.streamer.getStreams (code, data) ->
					if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{streams: data }}
					else console.log "WARNING Error controller: " + data

				if sys.sample && sys.classe then me.dataset.addCurrent sys.sample, sys.classe, me.streamer.getSampleFile(), (code, data) ->
						if !code then console.log 'Added sample ' + data
						else console.log 'Error adding sample: ' + data

				# CLASSIFIER EVENT

				if sys.classifier?.reload?
					me.classifier.stop()
					me.classifier.init()

				if sys.classifier?.toggle  then me.classifier.toggleClassifier sys.classifier?.toggle, (code, data) ->
						if !code then console.log 'Toggle of classifier ' + data + ' done.'
						else console.log 'Toggle of classifier ' + sys.classifier?.toggle + ' failed.' + data

				if sys.classifier?.list? then me.classifier.getAvailableClassifiers (code,data) ->
					if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{classifier:{list: data }}}
					else console.log "WARNING Error controller: " + data

				# TRAINING EVENTS
				if sys.training?.list? then me.dataset.getTrainingSets (code,data) ->
					if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.training?.build then 	me.dataset.buildClassifier sys.training.build,  sys.training.filter_low, sys.training.filter_high,  sys.training.structure, sys.training.epoch, sys.training.learning_rate, (code,data) ->
					if 			code == 0
						me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'done',data:data}}}
						me.classifier.getAvailableClassifiers (code,data) ->
							if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{classifier:{list: data }}}
							else console.log "WARNING Error controller: " + data
					else if code == 1  then	me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'running',data:data}}}
					else me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{build:sys.training.build, status:'failed',out:data}}}

				if sys.training?.do == 'next' then me.dataset.getNextTraining sys.training.show, sys.training.filter_low, sys.training.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{show:data}}}

				if sys.training?.do == 'prev' then me.dataset.getPrevTraining sys.training.show, sys.training.filter_low, sys.training.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{show:data}}}


				# DATASET EVENTS
				if sys.dataset?.list? then me.dataset.getDatasets (code,data) ->
					if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.dataset?.build then 	me.dataset.buildDataset sys.dataset?.build, (code,data) ->
					#console.log data
					if 			code == 0
						me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'done',data:data}}}
						me.dataset.getTrainingSets (code,data) ->
							if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{training:{list: data }}}
							else console.log "WARNING Error controller: " + data

					else if code == 1  then	me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'running',data:data}}}
					else me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{build:sys.dataset.build, status:'failed',out:data}}}

				if sys.dataset?.delete then 	me.dataset.deleteSample sys.records?.delete, (code,data) ->
					if !code then	me.dataset.getPrevSample sys.dataset?.delete, (code,data) ->
							me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}
					else console.log "WARNING Delete sample: " + sys.dataset?.delete + " failed. \n("+data+")"

				if sys.dataset?.do == 'next' then me.dataset.getNextSample sys.dataset.show, sys.dataset.filter_low, sys.dataset.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}

				if sys.dataset?.do == 'prev' then me.dataset.getPrevSample sys.dataset.show, sys.dataset.filter_low, sys.dataset.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{show:data}}}

				# DATABASE RECORD EVENTS
				if sys.records?.list?	then me.dataset.getDatabases (code, data) ->
					if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{list: data }}}
					else console.log "WARNING Error controller: " + data

				if sys.records?.build
					me.dataset.buildDatabase sys.records?.build, (code,data) ->
						#console.log data
						if 			code == 0
							me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'done',data:data}}}
							me.dataset.getDatasets (code,data) ->
								if !code then me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{dataset:{list: data }}}
								else console.log "WARNING Error controller: " + data
						else if code == 1  then	me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'running',data:data}}}
						else me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{build:sys.records.build, status:'failed',out:data}}}

				if sys.records?.delete then 	me.dataset.deleteRecord sys.records?.delete, (code,data) ->
					if code then	console.log "WARNING Delete sample: " + sys.records?.delete + " failed. \n("+data+")"

				if sys.records?.do == 'next' then me.dataset.getNextRecord sys.records.show, sys.records.filter_low, sys.records.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{show:data}}}

				if sys.records?.do == 'prev' then me.dataset.getPrevRecord sys.records.show, sys.records.filter_low, sys.records.filter_high, (code,data) ->
					me.serv.io.sockets.emit 'sys', JSON.stringify {sys:{records:{show:data}}}


conf = {}
conf.port = 2134
conf.chainAPI_url = '';
conf.chainAPI_site = '';
conf.source_url = '';

conf = require('../conf.json')[process.env.NODE_ENV || 'demo'];
console.log conf

new controller(conf.port, conf.source_url, conf.chainAPI_url, conf.chainAPI_site)
