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

  deleteSample: (classe, f) ->
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      file = me.databasePath + classe + '/' + items[me.num];
      fs.unlink file, (err) ->
        if err then  f(-1, "Error deletion of "+ file)
        else  f(0, "Deletion of "+ file + " done.")

  buildClassifier: (name, f) ->
    dst = me.classifierPath + 'classifier-' + name.split('.')[0] + '.nn';
    ctr = spawn 'octave', ['octave/build_classifier.m', '--train='+me.trainingsetPath + name, '--classifier-out='+dst, '--dbn']
    ctr.stdout.on 'data', (data)  -> f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  -> f?(-1, data.toString());
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
    ctr = spawn 'octave', ['octave/build_database.m', '--folder-in='+me.databasePath + name + '/', '--file-out='+dst, '--classe='+ name]
    ctr.stdout.on 'data', (data)  -> f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  -> f?(-1, data.toString());
    ctr.on 'close', (code)        -> f?(0,  '');

  buildDataset: (name, f) ->
    dst = me.trainingsetPath + name;
    ctr = spawn 'octave', ['octave/build_dataset.m', '--file-in='+name, '--file-out='+dst, '--classe='+ name]
    ctr.stdout.on 'data', (data)  -> f?(1,  data.toString())#out += data
    ctr.stderr.on 'data', (data)  -> f?(-1, data.toString());
    ctr.on 'close', (code)        -> f?(0,  '');


   createFFT: (name) ->
    file = me.databasePath + name.substr(1, name.indexOf('(')-1) + '/' + name
    chan = name.substr(name.indexOf('(')+1, 1)
    dst = 'tmp/database-fft.png';
    ctr = spawn 'octave', ['octave/printFFT.m', '--file-in='+ file, '--chan='+chan, '--file-out='+ dst]
    ctr.stderr.on 'data', (data)  -> f?(-1, data);
    ctr.on 'close', (code)        -> f?(0, dst);

  me.num = 0;
  getNextSample: (classe, f) ->
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      if ++me.num >= items.length then me.num = 0
      me.prototype.createFFT(items[me.num])
      f(0,{num:me.num, class:items[me.num].substr(0,1), size:items.length, path: me.databasePath + classe + '/' + items[me.num]})

  getPrevSample: (classe, f) ->
    fs.readdir me.databasePath + classe , (err, items) ->
      if items.length == 0
        f -1, "No file in " + me.databasePath + classe
        return
      if --me.num < 0 then me.num = 0
      me.prototype.createFFT(items[me.num])
      f(0, {num:me.num, class:items[me.num].substr(0,1), size:items.length, path: me.databasePath + classe + '/' + items[me.num]})



exports.Dataset = Dataset
