spawn = require('child_process').spawn
fs    = require('fs')

class Dataset
  me = this;

  constructor: ->
    me.databasePath     = @databasePath    = "data/database/"
    me.datasetPath      = @datasetPath     = "data/dataset/"
    me.trainingsetPath  = @trainingsetPath = "data/training/"
    me.classifierPath  = @classifierPath   = "data/classifiers/"

  addCurrent: (name, cl, sample_file_path, f) ->
    folder = me.databasePath + '/' + name.substr(0,name.indexOf('(')) + '/';
    fs.mkdir folder, (code, data) ->
      dst =  folder + cl + name + '_'+ new Date().getTime() + '.wav'
      ctr = spawn 'cp', [sample_file_path, dst]
      ctr.stderr.on 'data', (data)  -> f?(-1, data);
      ctr.on 'close', (code)        -> f?(0, dst);

  deleteRecord: (classe, f) ->
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      file = me.databasePath + classe + '/' + items[me.num_record];
      fs.unlink file, (err) ->
        if err then  f(-1, "Error deletion of "+ file)
        else  f(0, "Deletion of "+ file + " done.")

  buildClassifier: (name, filter_low = 1000, filter_high=10000, structure="10-10", epoch=200, learning_rate=0.01, f) ->
    console.log structure
    dst = me.classifierPath + 'classifier-' + name.split('.')[0] + '.nn';
    ctr = spawn 'octave', ['octave/build_classifier.m',
     '--train='+me.trainingsetPath + name,
      '--classifier-out='+dst,
      '--dbn',
      '--structure=' + structure,
      '--epoch='+epoch,
      '--learning_rate='+learning_rate,
      '--shape-left=' + filter_low,
      '--shape-right=' + filter_high]
    ready = false
    ctr.stdout.on 'data', (data)  ->
          #console.log data.toString()
          if data.toString().indexOf('Starting') != -1
            ready = true
          if !ready then return
          f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  ->
      console.log data.toString()
      f?(-1, data.toString());
    ctr.on 'close', (code)        -> f?(0,  '');

  getTrainingSets: (f) ->
    fs.readdir me.trainingsetPath, (err, items) ->
      if items == null
        f(-1, "Training folder empty: " + me.trainingsetPath)

      res = [];
      for trainingset in items
        if fs.lstatSync(me.trainingsetPath+trainingset).isFile then res.push(trainingset)
      f(0, res)

  getDatabases: (f) ->
    fs.readdir me.databasePath, (err, items) ->
      if items == null
        f(-1, "Dataset folder empty: " + me.databasePath)

      res = [];
      for database in items
        if fs.lstatSync(me.databasePath+database).isDirectory then res.push(database)
      f(0, res)

  getDatasets: (f) ->
    fs.readdir me.datasetPath, (err, items) ->
      if items == null
        f(-1, "Dataset folder empty: " + me.datasetPath)

      res = [];
      for dataset in items
        if fs.lstatSync(me.datasetPath+dataset).isFile then res.push(dataset)
      f(0, res)

  buildDatabase: (name, f) ->
    out = ''
    dst = me.datasetPath + name + '.dat';
    ctr = spawn 'octave', ['octave/build_database.m',
      '--folder-in='+me.databasePath + name + '/',
      '--file-out='+dst, '--classe='+ name
    ]
    ready = false
    ctr.stdout.on 'data', (data)  ->
      if data.toString().indexOf('Starting') != -1
        ready = true
      if !ready then return
      f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  -> f?(-1, data.toString());
    ctr.on 'close', (code)        -> f?(0,  '');

  buildDataset: (name, f) ->
    dst = me.trainingsetPath + name;
    ctr = spawn 'octave', ['octave/build_dataset.m',
    '--file-in='+name,
     '--file-out='+dst,
      '--classe='+ name
    ]
    ready = false
    ctr.stdout.on 'data', (data)  ->
          #console.log data.toString()
          if data.toString().indexOf('Starting') != -1
            ready = true
          if !ready then return
          f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  ->
      console.log data.toString()
      f?(-1, data.toString());
    ctr.on 'close', (code)        -> f?(0,  '');




  me.num_sample = 0
  me.current_dataset = null
  me.ctr_dataset = spawn('octave', ['octave/printFFT-dataset.m'])
  me.ready = false
  me.ctr_dataset.stderr.on 'data', (data)  ->
    console.log 'error : ' + data.toString()
    f?(-1, data)

  msg = ''
  me.ctr_dataset.stdout.on 'data', (data)  ->
    data = data.toString();
    #console.log data
    if data.indexOf('Starting') != -1
      me.ready = true
      return
    if !me.ready then return
    tmp = data.toString().toString().split("\n")
    msg += tmp[0]
    if tmp.length > 1
      try
        obj = JSON.parse(msg)
        if obj?.dataset
           me.current_dataset = obj.dataset
      catch err
      msg = tmp[1]
  me.ctr_dataset.on 'close', (code) ->

  getNextTraining: (trainer, filter_low, filter_high, f) ->
    if !trainer then f(-1, "No input " + trainer)
    file = me.trainingsetPath + trainer
    if me.current_dataset?.file != file
      me.ctr_dataset.stdin.write('" --file-in='+file+'"\x0A');
    me.ctr_dataset.stdin.write('" '+
      '--next ' +
      ' --num=' + me.num_sample +
      ' --filter-low='+filter_low +
      ' --filter-high='+filter_high + '"\x0A');
    if me.current_dataset then setTimeout (->
        f?(0, {
          num:me.current_dataset.num,
          type:'training',
          dataset:me.current_dataset
          })), 100

  getPrevTraining: (trainer, filter_low, filter_high, f) ->
    if !trainer then f(-1, "No input " + trainer)
    file = me.trainingsetPath + trainer
    if me.current_dataset?.file != file
      me.ctr_dataset.stdin.write('" --file-in='+file+'"\x0A');
    me.ctr_dataset.stdin.write('" '+
      '--prev ' +
      ' --num=' + me.num_sample +
      ' --filter-low='+filter_low +
      ' --filter-high='+filter_high + '"\x0A');
    if me.current_dataset then  setTimeout (->
        f?(0, {
          num:me.current_dataset.num,
          type:'training',
          dataset:me.current_dataset
          })), 100


  getNextSample : (dataset, filter_low, filter_high, f) ->
    if !dataset then f(-1, "No input " + dataset)
    file = me.datasetPath + dataset
    if me.current_dataset?.file != file
      me.ctr_dataset.stdin.write('" --file-in='+file+'"\x0A');
    me.ctr_dataset.stdin.write('" '+
      '--next ' +
      ' --num=' + me.num_sample +
      ' --filter-low='+filter_low +
      ' --filter-high='+filter_high + '"\x0A');
    if me.current_dataset then setTimeout (->
        f?(0, {
          num:me.current_dataset.num,
          type:'datasets',
          dataset:me.current_dataset
          })), 100

  getPrevSample : (dataset, filter_low, filter_high, f) ->
    if !dataset then f(-1, "No input " + dataset)
    file = me.datasetPath + dataset
    if me.current_dataset?.file != file
      me.ctr_dataset.stdin.write('" --file-in='+file+'"\x0A');
    me.ctr_dataset.stdin.write('" '+
      '--prev ' +
      ' --num=' + me.num_sample +
      ' --filter-low='+filter_low +
      ' --filter-high='+filter_high + '"\x0A');
    if me.current_dataset then  setTimeout (->
        f?(0, {
          num:me.current_dataset.num,
          type:'datasets',
          dataset:me.current_dataset
          })), 100

  deleteSample: (classe, f) ->
    console.log 'Delete sample ' + me.num_sample + ' from ' + me.current_dataset.file









   createFFT: (file, chan, filter_low = 1000, filter_high=10000) ->
    #file = me.databasePath + name.substr(1, name.indexOf('(')-1) + '/' + name
    #chan = name.substr(name.indexOf('(')+1, 1)
    dst = 'tmp/database-fft.png';
    ctr = spawn 'octave', ['octave/printFFT.m',
      '--file-in='+ file,
      '--chan='+chan,
      '--file-out='+ dst,
      '--filter-low=' + filter_low,
      '--filter-high=' + filter_high]
    ctr.stderr.on 'data', (data)  ->
#     console.log data.toString()
      f?(-1, data)
    ctr.stdout.on 'data', (data)  ->
#      console.log data.toString()
      f?(1,data)
    ctr.on 'close', (code)        -> f?(0, dst)



  me.num_record = 0;
  me.current_record = "";
  getNextRecord: (classe, filter_low, filter_high, f) ->
    if classe != '' then me.current_record = classe
    else                 classe = me.current_record
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      if ++me.num_record >= items.length then me.num_record = 0
      file = me.databasePath + items[me.num_record].substr(1, items[me.num_record].indexOf('(')-1) + '/' + items[me.num_record]
      chan = items[me.num_record].substr(items[me.num_record].indexOf('(')+1, 1)
      me.prototype.createFFT(file, chan, filter_low, filter_high)
      f(0,{
        num:me.num_record,
        type:'records',
        class:items[me.num_record].substr(0,1),
        size:items.length,
        path: me.databasePath + classe + '/' + items[me.num_record]
        })

  getPrevRecord: (classe, filter_low, filter_high, f) ->
    if classe != '' then me.current_record = classe
    else                 classe = me.current_record
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      if --me.num_record < 0 then me.num_record = 0
      file = me.databasePath + items[me.num_record].substr(1, items[me.num_record].indexOf('(')-1) + '/' + items[me.num_record]
      chan = items[me.num_record].substr(items[me.num_record].indexOf('(')+1, 1)
      me.prototype.createFFT(file, chan, filter_low, filter_high)
      f(0, {
        num:me.num_record,
        type:'records',
        class:items[me.num_record].substr(0,1),
        size:items.length,
        path: me.databasePath + classe + '/' + items[me.num_record]
        })

exports.Dataset = Dataset
