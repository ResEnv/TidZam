/****************************************
*
/***************************************/
function Controller(parent){
  this.parent = parent;
  var conf = null;

  var player = this.player = new Player(parent);
  var charts = this.charts = new ClassifierChart(parent);
  var speakerstats = this.speakerstats = new SpeakerStats(parent);

  // WINDOWS DECLARATION
  this.parent.innerHTML += '<div id="dialog-console" title="JSON WebSocket" ></div>'+
                           '<div id="dialog-console-data" title="JSON WebSocket data" ></div>';

  $( "#dialog-console-data" ).dialog({
    autoOpen: false,
    width: 272,
    modal: false,
  });
  $( "#dialog-console-data" ).html(
    '<div id="dialog-data-output" style="height:230px;"></div>'
  );
  $( "#dialog-console-data" ).attr('style','font-size:12px;');



  $( "#dialog-console" ).dialog({
    autoOpen: false,
    width: 272,
    modal: false,
  });
  $( "#dialog-console" ).html(
    '<div id="dialog-output" style="height:230px;"></div>' +
    '<input type="text" id="dialog-event" style="width:30px;" value="sys">'+
    '<input type="text" id="dialog-input" style="width:160px;">'+
    '<input type="button" id="dialog-send" value="Send">'
  );

  $( "#dialog-send" ).on("click", function(){
    console.log ("click " + $( "#dialog-event" ).val() + " " + $( "#dialog-input" ).val());
    socket.emit($( "#dialog-event" ).val(),$( "#dialog-input" ).val());
  });

  $( "#dialog-console" ).attr('style','font-size:12px;');


  // WINDOWS CALLER
  this.raz = function(){
    socket.emit('sys', JSON.stringify( {sys:{init:''}}));
    setTimeout(function(){
      socket.emit('sys', JSON.stringify({sys:{dataset:{list:''}} }));
    }, 500);

  }

  this.openSpeakerstats = function(){
    this.speakerstats.show();
  };

  this.openPlayer = function(){
    this.player.show();
  };

  this.openNeuralOutputs = function(){
    this.charts.show();
  };

  this.openConsole = function(){
    $( "#dialog-console" ).dialog("open");
  };

  this.openDataConsole = function(){
    $( "#dialog-console-data" ).dialog("open");
  };


  // SOCKET. IO CONNECTOR
  socket.on('sys', function(msg){
    try {
      $( "#dialog-output" ).html(msg);
      json = JSON.parse(msg.toString());
      player.process(json);
      charts.process(json);
    }
    catch(err){
      console.log("Error on sys: " + err + " MSG received: "+ msg.toString());
    }
  });

  socket.on('data', function(msg){
    $( "#dialog-data-output" ).html(msg);
//    $( "#dialog-output" ).html(msg);
//    console.log(msg);
    try {
      json = JSON.parse(msg.toString());
      charts.process(json);
      //if (json.results)
      player.process(json);
      }
    catch(err){
       console.log("Error on data: " + err + " MSG received:  "+ msg.toString());
    }
  });
}
