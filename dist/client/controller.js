/****************************************
*
/***************************************/
function Controller(parent){
  this.parent = parent;
  var conf = null;

  var player = this.player = new Player(parent);
  var charts = this.charts = new ClassifierChart(parent);

  // WINDOWS DECLARATION
  this.parent.innerHTML += '<div id="dialog-console" title="JSON WebSocket" ></div>';

  $( "#dialog-console" ).dialog({
    autoOpen: false,
    width: 300,
    height: 400,
    modal: false,
  });
  $( "#dialog-console" ).html(
    '<div id="dialog-output" style="height:300px;"></div>' +
    '<input type="text" id="dialog-event" style="width:30px;">'+
    '<input type="text" id="dialog-input">'+
    '<input type="button" id="dialog-send" value="Send" style="width:100%;">'
  );

  $( "#dialog-send" ).on("click", function(){
    console.log ("click " + $( "#dialog-event" ).val() + " " + $( "#dialog-input" ).val());
    socket.emit($( "#dialog-event" ).val(),$( "#dialog-input" ).val());
  });

  $( "#dialog-console" ).attr('style','font-size:12px;');


  // WINDOWS CALLER
  this.openPlayer = function(){
    this.player.show();
  };

  this.openNeuralOutputs = function(){
    this.charts.show();
  };

  this.openConsole = function(){
    $( "#dialog-console" ).dialog("open");
  };


  // SOCKET. IO CONNECTOR
  socket.on('sys', function(msg){
    try {
      json = JSON.parse(msg.toString());
      player.process(json);
    }
    catch(err){
      console.log("Error on sys: " + err + " "+ msg.toString());
    }
  });

  socket.on('data', function(msg){
    $( "#dialog-output" ).html(msg);
//    console.log(msg);
    try {
      json = JSON.parse(msg.toString());
      charts.process(json);

      //if (json.results)
        player.process(json);
      }
    catch(err){
       console.log("Error on data: " + err + " "+ msg.toString());
    }
  });
}
