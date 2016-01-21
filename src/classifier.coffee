spawn = require('child_process').spawn
fs    = require('fs')

class Classifier
  me = this
  ctr = {}


  constructor: (file, clb, show = "") ->
    me.file = file
    me.show = show
    me.conf = {}
    me.clb  = clb
    me.classifiersPath = 'data/classifiers/'
    me.classifiers = []

  init: ->
    @getAvailableClassifiers (code, data) ->
      if code == 0
        me.classifiers = data
        me.prototype.start()
      else console.log 'Classifier initialization error'

  toggleClassifier: (name, f) ->
    @getAvailableClassifiers (code, data) ->
      found = false
      for cl in data
        if cl == 'classifier-' + name + '.nn'
           if me.classifiers.indexOf(cl) >= 0
             t = me.classifiers.splice(me.classifiers.indexOf(cl),1)
             found = true
           break;

      if !found
        me.classifiers.push('classifier-' + name + '.nn');
        t = 'classifier-' + name + '.nn'

      me.prototype.reload()
      f(0, t)

  getConf: ->
    me.conf

  getAvailableClassifiers: (f) ->
    res = []
    fs.readdir me.classifiersPath , (err, items) ->
      for nn in items
        if nn.indexOf 'nn' > 0
          res.push(nn)
      f(0, res)

  reload: ->
    @stop()
    @start()

  stop: ->
    ctr.kill?('SIGTERM')

  start: ->
    tmp =

    classifiers = '[{"' + me.classifiers[0] + '"}'
    me.classifiers.forEach (item, i) ->
      if (i>0)
        classifiers += ',{"' + item + '"}';

    classifiers += ']'
    classifiers = classifiers.replace(/(?:\r\n|\r|\n)/g, 'gg')
    # console.log classifiers

    ctr = spawn('octave',["./octave/predict.m","--auto", "--stream="+me.file, me.show, "--classifiers-path=" +me.classifiersPath, "--classifiers=" + classifiers]);

    msg = new String()
    ready = false

    ctr.stderr.on 'data', (data) ->
        console.log data.toString()

    ctr.stdout.on 'data', (data) ->
      #console.log data.toString()
      if data.toString().indexOf('Starting') != -1
        ready = true
      if !ready then return

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
      console.log 'Classifiers stopped'

exports.Classifier = Classifier
