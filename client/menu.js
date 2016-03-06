
function Menu (controller, parent) {

  this.parent = parent;
  this.id = new Date().getTime();


  this.recorder = {
    add:function(){
      console.log("add");
    }
  };

  this.parent.innerHTML += '<ul id="menu'+ this.id + '"> \
  <li class="ui-state-disabled">TidMarsh</li>\
  <li>JSON Sockets\
  <ul> \
    <li OnClick="controller.openConsole();"> JSON WebSocket</li>\
    <li OnClick="controller.openDataConsole();"> JSON WebSocket data</li>\
  </ul></li>\
  <li OnClick="recorder.show()"> Learning</li>          \
  <li>Views\
  <ul> \
  <li OnClick="controller.openPlayer();"> Player </li>\
  <li OnClick="controller.openSpeakerstats();"> Speaker stats </li>\
  <li OnClick="controller.openNeuralOutputs();"> Online Chart View</li>\
  </ul>\
  </li> \
  </ul>\
  ';
  $( '#menu'+ this.id ).menu();
}
