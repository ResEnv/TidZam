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
    modal: false,
  });


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
      console.log("Error on received data: " + msg.toString());
    }
  });

  socket.on('data', function(msg){
    $( "#dialog-console" ).html(msg);
    try {
      json = JSON.parse(msg.toString());
      player.process(json);
      charts.process(json);
    }
    catch(err){
      // console.log("Error on received data: " + msg.toString());
    }
  });
}
