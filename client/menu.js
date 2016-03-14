
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
  <li>Debug\
  <ul> \
    <li OnClick="controller.openConsole();"> JSON WebSocket</li>\
    <li OnClick="controller.openDataConsole();"> JSON WebSocket data</li>\
  </ul></li>\
  <li OnClick="recorder.show()"> Learning</li>          \
  <li>Interfaces\
  <ul> \
  <li OnClick="controller.openPlayer();"> Controller </li>\
  <li OnClick="controller.openNeuralOutputs();"> Classifier Management</li>\
  <li OnClick="controller.openSpeakerstats();"> Speaker Recognition Plugin </li>\
  </ul>\
  </li> \
  </ul>\
  ';
  $( '#menu'+ this.id ).menu();
}
