http   = require('http')
io     = require("socket.io-client")

class chainAPI

  debug_level = 0
  sample_timestamp = "";

  options = {
    hostname: 'chain-api.media.mit.edu',
    port: 80,
    auth: 'slash:toto',
    path: '/sites/',
    method: 'GET',
    site: 'tidzam_test',
    site_id: 16
  };
  constructor: (port, chainAPI_url) ->
    @me = me = this
    options.hostname = chainAPI_url
    client  = io.connect("http://localhost:" + port)
    @client = client

    client.on 'connect', ->
      console.log '[chainAPI] Socket.io Client initialized'

    client.on 'sys', (msg) ->
      try

        obj = JSON.parse(msg)
        # Compute the timestamp of current sample according to one of input filename
        if obj.sys.url || 0
          pos = obj.sys.url.indexOf 'cell3a-'
          if pos >= 0
            name = obj.sys.url.substr pos+7, (obj.sys.url.indexOf('.ogg')-(pos+7))
            sample_timestamp = name.substr(0, 10) + ' ' + name.substr(11).replace(/-/g,':')
            sample_timestamp = (new Date(sample_timestamp))
            sample_timestamp = new Date(sample_timestamp.getTime() + 250*obj.sys.sample_count - sample_timestamp.getTimezoneOffset()*60000) # GMT offset due to
            sample_timestamp = sample_timestamp.toISOString()
          else sample_timestamp = ''
      catch err
        return
      #me.debug '[CHAIN_API] sys event: ' + msg.toString()

    last_result = [];
    client.on 'data', (msg) ->
      #me.debug '[CHAIN_API] data event: ' + msg.toString()
      try
        obj = JSON.parse(msg)
      catch err
        return

      if (!obj.analysis || 0)
        return

       # FILTER
      if obj.analysis.result.indexOf('->') != -1 then return
      found = false
      for el in last_result
        if el.chan == obj.chan
          if el.value == obj.analysis.result[0] then return
          else el.value = obj.analysis.result[0]
          found = true
      if !found then last_result.push({chan:obj.chan, value:obj.analysis.result[0]})

      # SELECT or ADD the Device / microphone
      device = "audio-stream_" + obj.chan
      me.getDeviceId device, (code, DeviceName, DeviceId) ->
        if code == -1
          me.addDevice DeviceName, (code, data) ->
            me.debug '[chainAPI] Push new device :' + DeviceName + ' ('+code+')'
          return

        for el in last_result
          if el.chan == obj.chan
            if el.value == "Don t Know"
              classifier = {"Don t Know": 1}

        # SELECT or ADD the Sensor / classifier
        for classifier, value of obj.analysis.predicitions
          me.getSensorId DeviceId, classifier, (code, classifier, SensorId) ->
            if code == -1
              me.addSensor DeviceId, classifier, (code, data) ->
                me.debug '[chainAPI] Push new sensor-classifier :' +  classifier + ' ('+code+')' + data
              return

            # PUSH the sensor / classifier output value
            me.addData SensorId, value, (code, res) ->
              me.debug '[chainAPI]] Push new data for ' + classifier + ': ' + value + '\n' + res

  ###
     Data = Classifier Output
  ###

  addData: (SensorId, value, f) ->
    if sample_timestamp != ''
      payload = '{"value": '+value+', "timestamp":"'+sample_timestamp+'"}'
    else payload = '{"value": '+value+'}'
    options.path = '/scalar_data/create?sensor_id='+SensorId
    options.method = 'POST'
    req = http.request options, (res) ->
      res.on 'data', (d) => f(0, d)
    req.write(payload);
    req.end();
    req.on 'error', (e) => f(-1, e)

  ###
     Sensor = Classifier
  ###
  addSensor: (DeviceId, SensorName, f) ->
    payload = '{"sensor-type": "scalar", "metric": "'+SensorName+'", "unit": "prob"}'
    options.path = '/sensors/create?device_id='+DeviceId
    options.method = 'POST'
    req = http.request options, (res) ->
      res.on 'data', (d) => f(0, d)
    req.write(payload);
    req.end();
    req.on 'error', (e) => f(-1, e)

  getSensorId: (DeviceId, SensorName, f) ->
    options.path = '/sensors/?device_id='+DeviceId
    options.method = 'GET'
    req = http.request options, (res) ->
      res.on 'data', (d) =>
        obj = JSON.parse(d)
        done = false
        for element in obj._links.items
          if element.title == SensorName
            done = true
            id = element.href.substr 15+element.href.search /scalar_sensors/
            f(0, SensorName, id)
        if done == false
          f(-1, SensorName)
    req.end();
    req.on 'error', (e) => f(-2, SensorName)


  ###
     Device = Channel
  ###
  addDevice: (DeviceName, f) ->
    payload = JSON.stringify {name: DeviceName}
    options.path = '/devices/create?site_id='+options.site_id
    options.method = 'POST'
    req = http.request options, (res) ->
      res.on 'data', (d) => f(d)
    req.write(payload);
    req.end();
    req.on 'error', (e) => f(e)

  getDeviceId: (DeviceName, f) ->
    options.path = '/devices/?site_id='+options.site_id
    options.method = 'GET'
    req = http.request options, (res) ->
      res.on 'data', (d) =>
        obj = JSON.parse(d)
        done = false
        for element in obj._links.items
          if element.title == DeviceName
            done = true
            id = element.href.substr 8+element.href.search /devices/
            f(0, DeviceName, id)
        if done == false
          f(-1, DeviceName)
    req.end();
    req.on 'error', (e) => f(-2, DeviceName)

  debug: (msg) ->
    if debug_level > 0
      console.log msg

exports.chainAPI = chainAPI
