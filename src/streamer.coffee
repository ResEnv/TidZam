spawn = require('child_process').spawn
fs = require('fs')

class Streamer
  me = this
  me.ctr_buffering = null


  constructor: (f) ->
    me.buffer_path  = "tmp/"
    me.sample_file  = me.buffer_path + "sample.wav"
    me.SAMPLE_SIZE  = 0.5
    me.OVERLAP      = 0.5
    me.sample_count = 0
    @url = me.url   = "stream.ogg"
    me.state        = "loading"
    me.clb          = f
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

  getSampleFile: ->
    me.sample_file

  setState: (state) ->
    me.state = state
    me.clb(state)

  getSampleCount: ->
    me.sample_count

  startBuffering: (path, f) ->

    ###
    console.log 'Buffering from ' + path
    #if path.toString().indexOf('.wav') < 0 and path.indexOf('http:') > 0
    #  me.ctr_buffering  = spawn 'cp', [path, me.buffer_path]

    #else
    me.ctr_buffering = spawn 'mpg123', ["-r","48000", "-w", me.buffer_path + 'stream.wav', path]
    me.ctr_buffering.stderr.on 'data', (data)  ->
      console.log '** ERROR **Stream buferring :' + path + '( '+ data + ')'
    me.prototype.initSample()
    me.prototype.setState('ready')
    setTimeout me.prototype.play, 1500


    ###
    dst = me.buffer_path + 'stream.ogg'
    if isURL (path)
      console.log 'Buffering from url ' + path
      # -fs limit the size of buffer file then reload
      me.ctr_buffering = spawn 'ffmpeg', ["-y", "-r", "48000", "-i", path, "-fs", 10000000,  me.buffer_path + 'stream.wav']
      me.ctr_buffering .on 'close', (code) ->
        if code == 0
          me.prototype.startBuffering(path, f)

      me.prototype.initSample()
      me.prototype.setState('ready')

      if me.state == "pause" || me.state == "terminated"
        setTimeout me.prototype.play, 1500

    else
      path = me.streamPath + path;
      console.log 'Buffering from local file ' + path
      ctr = spawn 'cp', [path, dst]
      ctr.stderr.on 'data', (data)  ->  f(-1, data);
      ctr.on 'close', (code)        ->  f(0, dst);
      dst

  convertOggtoWav: (file, f) ->
    dst = me.buffer_path + 'stream.wav'
    console.log 'Converting from '+file+' to '+dst
    ctr = spawn 'oggdec', ["-o", dst, file]
    ctr.stderr.on 'data', (data)  ->
    ctr.on 'close', (code)        ->  f(0, dst);
    dst



  loading: ->
    @setState('loading')
    me.ctr_bufferin?.stdin?.pause();
    me.ctr_buffering?.kill()

    if @url.indexOf('microphone') != -1
      me.ctr_buffering = spawn 'arecord', ["-f","dat",me.buffer_path + 'stream.wav']
      me.ctr_buffering.stdout.on 'data', ->
      me.prototype.initSample()
      me.prototype.setState('ready')
      setTimeout me.prototype.play, 1500
    else
      @startBuffering @url, (code, data) ->
        if !code || 0
          me.prototype.convertOggtoWav data, (code, data) ->
            if !code || 0
              me.prototype.initSample()
              me.prototype.setState('ready')
            else me.prototype.setState('error wav convertion')
        else me.prototype.setState('error loading')

  initSample: -> me.sample_count = 0;
  splitSample:  (f) ->
      file  = me.buffer_path + 'stream.wav'
      dst   = me.sample_file
      begin = me.sample_count * (1-me.OVERLAP) * me.SAMPLE_SIZE;

      ctr = spawn('sox', [file, dst, "trim", begin, me.SAMPLE_SIZE]);
      ctr.stderr.on 'data', (data)  -> f(-1, data);
      ctr.on 'close', (code)        -> f(0, dst);

  getSample: (f2) ->
    @splitSample (code, data) ->
      if !code || 0
        if me.state != 'terminated'
          f2(0, "Next sample done");
      else
        f2(-1, "Stream ended");
        #me.prototype.initSample()

  play:  () ->
    if me.state == "pause" || me.state == "terminated"
      me.prototype.setState("ready")
      return
    me.prototype.control("next")
    setTimeout me.prototype.play, me.SAMPLE_SIZE*1000*(1-me.OVERLAP)

  pause: ->
    me.prototype.setState('pause')

  control: (ctr) ->
    switch (ctr)
      when 'resume' then  @loading()
      when 'play' then  @play()
      when 'pause' then @pause()

      when "prev"
        if me.sample_count > 0 then  me.sample_count--
        @getSample (code, msg) ->
          if code == -1
            state = 'terminated'
          else state = 'ready'
          me.prototype.setState(state)

      when "next"
        me.sample_count++
        @getSample (code, msg) ->
          if code == -1
            state = 'ready' #'terminated'
            me.sample_count--
          else state = 'ready'
          me.prototype.setState(state)

      else  console.log 'Unavailable control: ' + ctr

isURL = (str) ->
  new RegExp("([a-zA-Z0-9]+://)([a-zA-Z0-9_]+:[a-zA-Z0-9_]+me.)?([a-zA-Z0-9.-]+\\.[A-Za-z]{2,4})(:[0-9]+)?(/.*)?").test(str)

exports.Streamer = Streamer
