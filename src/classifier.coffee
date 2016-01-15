spawn = require('child_process').spawn

class Classifier
  me = this

  constructor: (file, clb, show = "") ->
    me.file = file
    me.show = show
    me.conf = {}
    me.clb  = clb

  getConf: ->
    me.conf

  start: ->
    ctr = spawn('octave',["./octave/predict.m","--auto", "--stream="+me.file, me.show]);
    msg = new String()
    ctr.stdout.on 'data', (data) ->
#      console.log data.toString()
      tmp = data.toString().toString().split("\n")
      msg += tmp[0]

      if tmp.length > 1
        try
          tmp2 = JSON.parse(msg.toString())
          if tmp2.classifiers
            me.conf	= tmp2;
        catch err then #console.log 'Classifier error: ' + err
        me.clb 0, msg
        msg = tmp[1]

    ctr.stdout.on 'close', (code) ->
      me.prototype.start()

exports.Classifier = Classifier
