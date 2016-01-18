
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
  <li>Dataset          \
  <ul>                       \
  <li OnClick="recorder.show()">Record Databases</li>                \
  <li OnClick="dataset_train.show()">Training Datasets</li>                \
  <li OnClick="classifiers.show()">Classifier Training</li>                \
  </ul>                       \
  </li> \
  <li>Sound Recognition Engine\
  <ul> \
  <li OnClick="controller.openPlayer();"> Controller </li>\
  <li OnClick="controller.openNeuralOutputs();"> Chart View</li>\
  </ul>\
  </li> \
  </ul>\
  ';
  $( '#menu'+ this.id ).menu();
}
