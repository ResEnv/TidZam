
function Menu (controller, parent) {

  this.parent = parent;
  this.id = new Date().getTime();


  this.recorder = {
    add:function(){
      console.log("add");
    }
  };

  this.parent.innerHTML += '<ul id="menu'+ this.id + '"> \
  <li OnClick="controller.openConsole();"> JSON WebSocket</li>\
  <li class="ui-state-disabled">TidMarsh</li>\
  <li>Sample Recorder          \
  <ul>                       \
  <li OnClick="recorder.add()"> Add </li>                \
  </ul>                       \
  </li> \
  <li>Dataset Builder</li> \
  <li>Classifier Trainer</li> \
  <li>Neural Knowledge Unit\
  <ul> \
  <li OnClick="controller.openPlayer();"> Controller </li>\
  <li OnClick="controller.openNeuralOutputs();"> Grahical View</li>\
  </ul>\
  </li> \
  </ul>\
  ';
  $( '#menu'+ this.id ).menu();
}
