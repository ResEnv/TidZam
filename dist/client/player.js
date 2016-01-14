function Player(parent){

  parent.innerHTML +=  '<div id="dialog-player" title="Controller" style="width:100%;"></div>';

  var audio_html =
  '<audio id="audio_player">    \
  <source src="/stream/" type="audio/wav" />    \
  </audio>                                          \
  <span id="state" style="text-align:center;width:100%;">State</span><br> \
  OGG Stream:            \
  <select id="audio_selection">\
  <option value="/stream/">From Online Sampling (delayed)</option>\
  <option value="http://doppler.media.mit.edu:8000/audiocell3a.ogg">From doppler.media.mit.edu</option>\
  </select><br><br>\
  <span id="results" style="text-align:center;width:100%;">Results</span>\
  ';

  this.dialog = $( '#dialog-player'  ).dialog({
    autoOpen: false,
    height: 300,
    width: 470,
    modal: false,
    buttons: {
      Mute: function(){
        if (document.getElementById('audio_player' ).paused == false)
             $( '#audio_player' ).trigger('pause');
        else $('#audio_player' ).trigger('play');
      },
      Load: function(){
        $( '#audio_player'  ).load();
        $( '#audio_player' ).trigger('play');
        socket.emit('sys', JSON.stringify(
          {sys:{control:'load'}}
        ))
      },
      Play: function(){
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
    $( '#audio_player'  ).attr('src',
    $( '#audio_selection option:selected' ).val() + '?time='+ ((new Date()).getTime()));
    $( '#audio_player'  ).load();
    $( '#audio_player' ).trigger('play');
  });

  $( '#audio_selection'  ).on('change', function(ev, ui){
    $( '#audio_player'  ).attr('src',
    $( '#audio_selection option:selected' ).val());

    if (socket || 0)
      socket.emit('sys',"{ sys: { url: ' " + $( '#audio_selection option:selected' ).val() + " } }");
    else console.log("no socket");
  });
  /****/

  this.show = function(){
    this.dialog.dialog('open');
  }

  this.process = function(json){
    if (json.analysis && json.chan)
        $( '#results' ).html( 'Predictions: ' + json.analysis.result + ' (chan:' + json.chan + ')');


    /****/
  }
}
