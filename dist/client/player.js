function Player(parent){

  parent.innerHTML +=  '<div id="dialog-player" title="Controller" style="width:100%;"></div>';

  var audio_html =
  '<audio id="audio_player">    \
  <source src="/stream/" type="audio/wav" />    \
  </audio>                                          \
  <span id="state" style="text-align:center;width:100%;">State</span><br> \
  OGG Stream:            \
  <select id="audio_selection">\
  <option value="/stream/">stream.ogg</option>\
  </select><br><br>\
  <span id="results" style="text-align:center;width:100%;">Results</span>\
  <img src="/fft" id="img_fft">\
  ';

  this.dialog = $( '#dialog-player'  ).dialog({
    autoOpen: true,
    width: 690,
    modal: false,
    buttons: {
      Update: function(){
        socket.emit('sys', JSON.stringify(
          {sys:{streams:''}}
        ));
      },
      Mute: function(){
        if (document.getElementById('audio_player' ).paused == false)
             $( '#audio_player' ).trigger('pause');
        else $('#audio_player' ).trigger('play');
      },
      Resume: function(){
        socket.emit('sys', JSON.stringify(
          {sys:{control:'resume'}}
        ));
        $( '#audio_player'  ).load();
        $( '#audio_player' ).trigger('play');
      },
      Play: function(){
        if(!document.getElementById('audio_player').paused && !document.getElementById('audio_player').played.length)
          $( '#audio_player'  ).load();
        socket.emit('sys', JSON.stringify(
          {sys:{control:'play'}}
        ))
      },
      Pause: function(){
        socket.emit('sys', JSON.stringify(
          {sys:{control:'pause'}}
        ))
      },
      Prev: function(){
        socket.emit('sys', JSON.stringify(
          {sys:{control:'prev'}}
        ))
      },
      Next: function(){
        socket.emit('sys', JSON.stringify(
          {sys:{control:'next'}}
        ))
      }
    }
  });
  $('#dialog-player').html(audio_html);

  /****/

  socket.on('sys', function(msg){
    try {
      obj = JSON.parse(msg);
      if (! obj.sys) throw "not a sys object";
      $('#state').html('State: ' + obj.sys.state + ' sample-id ' + obj.sys.sample_count);
    }
    catch (err){
      console.log("WARNING: player socket error " + err);
    }
  });

  $( '#audio_player'  ).on('ended', function(){
    $( '#audio_player'  ).attr('src', '/stream/?time='+ ((new Date()).getTime()));
    $( '#audio_player'  ).load();
    $( '#audio_player' ).trigger('play');
  });

  $( '#audio_selection'  ).on('change', function(ev, ui){
    if (socket || 0){
      socket.emit('sys', '{ "sys": { "url": "' + $( '#audio_selection option:selected' ).val() + '" } }');
      socket.emit('sys', JSON.stringify(
        {sys:{control:'resume'}}
      ));
      $( '#audio_player'  ).load();
      $( '#audio_player' ).trigger('play');
    }
    else console.log("no socket");
  });
  /****/

  this.show = function(){
    this.dialog.dialog('open');
    socket.emit('sys', JSON.stringify(
      {sys:{streams:''}}
    ));
  }

  this.process = function(json){
    if (json.analysis && json.chan){
        document.getElementById('img_fft').src = '/fft?time='+((new Date()).getTime());
        $( '#results' ).html( 'Predictions: ' + json.analysis.result + ' (chan:' + json.chan + ')');
      }

    if(json.sys)
      if (json.sys.streams){
        $( '#audio_selection' ).empty();
        for (var i=0; i < json.sys.streams.length; i++)
          $( '#audio_selection' ).append($("<option></option>").attr("value", json.sys.streams[i]).text(json.sys.streams[i]));
        }
    /****/
  }
}
