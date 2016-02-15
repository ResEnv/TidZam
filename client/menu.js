
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
  <li OnClick="controller.openConsole();"> JSON WebSocket</li>\
  <li OnClick="controller.openDataConsole();"> JSON WebSocket data</li>\
  <li OnClick="recorder.show()"> NKU Compilation</li>          \
  <li>NKU Execution\
  <ul> \
  <li OnClick="controller.openPlayer();"> Controller </li>\
  <li OnClick="controller.openNeuralOutputs();"> Chart View</li>\
  </ul>\
  </li> \
  </ul>\
  ';
  $( '#menu'+ this.id ).menu();
}
