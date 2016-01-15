spawn = require('child_process').spawn

class Streamer
  me = this

  constructor: (f) ->
    me.buffer_path  = "tmp/"
    me.sample_file  = me.buffer_path + "sample.wav"
    me.SAMPLE_SIZE  = 0.5
    me.sample_count = 0
    @url = me.url   = "stream.ogg"
    me.state        = "loading"
    me.clb          = f

  getSampleFile: ->
    me.sample_file

  setState: (state) ->
    me.state = state
    me.clb(state)

  getSampleCount: ->
    me.sample_count

  startBuffering: (path, f) ->
    dst = me.buffer_path + 'stream.ogg'
    if isURL (path)
      console.log 'Buffering from url ' + path
      ctr = spawn 'streamripper', [path,"-M","1","-d", me.buffer_path]
      ctr = spawn 'cp', [me.buffer_path + '/Streamripper_rips/incomplete/ - Title Unknown.ogg', dst]
    else
      console.log 'Buffering from local file ' + path
      ctr = spawn 'cp', [path, dst]
    ctr.stderr.on 'data', (data)  -> f(-1, data);
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
      begin = me.sample_count * me.SAMPLE_SIZE;

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
        me.prototype.initSample()

  play:  () ->
    if me.state == "pause" || me.state == "terminated"
      me.prototype.setState("ready")
      return
    me.prototype.control("next")
    setTimeout me.prototype.play, me.SAMPLE_SIZE*1000

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
            state = 'terminated'
          else state = 'ready'
          me.prototype.setState(state)

      else  console.log 'Unavailable control: ' + ctr

isURL = (str) ->
  new RegExp("([a-zA-Z0-9]+://)([a-zA-Z0-9_]+:[a-zA-Z0-9_]+me.)?([a-zA-Z0-9.-]+\\.[A-Za-z]{2,4})(:[0-9]+)?(/.*)?").test(str)

exports.Streamer = Streamer
