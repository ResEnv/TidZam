fs = require('fs')

class Stream
  me = this
  constructor: () ->
    me.streamPath     = @streamPath    = "data/stream/"

  getStreamPath: ->
    @streamPath

  getStreams: (f) ->
	  fs.readdir me.streamPath, (err, items) ->
      if items == null
        f(-1, "Stream folder empty: " + me.streamPath)

      res = [];
      for store in items
        if /ogg/i.test(store) then res.push(store)
      f(0, res)


exports.Stream = Stream
