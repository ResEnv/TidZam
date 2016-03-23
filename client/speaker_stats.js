function SpeakerStats(parent, names){
  this.selectedClass = "";

  var PED_count = [['Speaker', 'Score']];
  var plots = this.plots = new Array();
  parent.innerHTML += '<div id="PED" title="Stream Analysis"><div id="PED_piechart" style="width:600px;height:600px; text-align:center;"></div><div id="PED_lists">No member</div>';


// New sample for cl (if cl do not exist, it will be create)
// socket.emit('sys', JSON.stringify( {sys:{sample: cl, classe:"+"}} ));
/*
* AUTO RECORD OF NEW SPEAKER
*/
  new_PED = "";
  new_PED_count = 0;

  /******************************************************************************/
  /* Views definitions                                                          */
  /******************************************************************************/

  parent.innerHTML += '<div id="progressbar"><div id="progress-label">Loading...</div></div><div id="PED_new"> ' +
    ' <div id="PED_new_init"><input type="text" id="PED_new_value"><input type="button" value="create" id="PED_new_button"></div>' +
      '<div id="PED_new_progress"> <input type="button" value="stop" id="PED_stop_button"> '+
      '<div id="PED_new_progress_bar"></div>'+
      "<br><strong>If using microphone,</strong><br>Please talk as clearly as possible while the extraction of samples. <br\> \
                <br>\
                Reading some following words can improve record quality and reduce process time ...<br> \
                <div style=\"border-width:1px; border-style:solid; border-color:black; \"> \
                19	/a/		cat, plaid, laugh <br> \
                20	/ā/		bay, maid, weigh, straight, pay, foyer, filet, eight, gauge, mate, break<br> \
                21	/e/		end, bread, bury, friend, said, many, leopard, heifer, aesthetic, say\<br> \
                22	/ē/		be, bee, meat, lady, key, phoenix, grief, ski, deceive, people, quay<br> \
                23	/i/		it, england, women, busy, guild, gym, sieve<br> \
                24	/ī/		spider, sky, night, pie, guy, stye, aisle, island, height, kite<br> \
                25	/o/		octopus, swan, honest, maul, slaw, fought<br> \
                26	/ō/		open, moat, bone, toe, sow, dough, beau, brooch, sew<br> \
                27	/oo/		wolf, look, bush, would<br> \
                28	/u/		lug, monkey, blood, double<br> \
                29	/ū/		who, loon, dew, blue, flute, shoe, through, fruit, manoeuvre, group<br> \
                30	/y//ü/		unit, you, knew, view, yule, mule, queue, beauty, adieu, feud<br> \
                31	/oi/		join, boy, buoy<br> \
                32	/ow/		now, shout, bough<br> \
                33	/ə/ (schwa)	about, ladder, pencil, dollar, honour, doctor, ticket, augur, centre<br> \
                </div>" +
      '</div>'+
  '</div>';
  $('#PED_new_progress').hide();

  $('#PED_stop_button').on('click',function(){
    stop_record = true;
  });

  $('#PED_new_button').on('click',function(){
    socket.emit('sys', JSON.stringify( {sys:{control:'pause'}} ));

    setTimeout( function(){
      console.log("create " + $('#PED_new_value').val());
      new_PED = $('#PED_new_value').val();
      state == "record";
      new_PED_count = 0;
      lock_loop_new = sample_count
      socket.emit('sys', JSON.stringify( {sys:{control:'next'}} ));
    }, 3000);
      $('#PED_new_init').hide();
      $('#PED_new_progress').show();
  })

  var dialog_new = $("#PED_new").dialog({
    autoOpen:false,
    title:'New record',
    width:600,
    height:400
  });



  // PROGRESS BAR

  var progressbar_win = $("#progressbar").dialog({
    autoOpen:false,
    title:'Progress',
    width:300,
    height:120
  });

  $('#progressbar').hide();
  var progressbar = $( "#progressbar" ),
    progressLabel = $( "#progress-label" );

  progressbar.progressbar({
    value: false,
    change: function() {
      progressLabel.text( progressbar.progressbar( "value" ) + "%" );
    },
    complete: function() {
      progressLabel.text( "Complete!" );
    }
  });
/******************************************************************************/
/* State machine for voice recording, encoding, training program and learning */
/******************************************************************************/
  function PED_start(){
    socket.emit('sys', '{ "sys": { "classifier": { "reload": ""}}}');
  }

  state_learning = '';
  // generate Training Program
  function PED_build_classifier_init(){

    function build_classifier_delay(name){
      setTimeout(function(){
        socket.emit('sys', '{ "sys": { "dataset": { "build": "' + name + '" } } }');
        }, (Math.ceil(1000 * Math.random()) ));
      }

    state_learning  = 'learning';
    progressbar_win.dialog("open");
    for (var i=0; i < dataset_list.length; i++)
      if(dataset_list[i].name.indexOf("Nothing") == -1)
      build_classifier_delay(dataset_list[i].name);
  }

  // If training program is generated, start learning process
  function PED_build_classifier(obj){
    if (state_learning != 'learning') return;

    if(obj.sys.dataset)
    if (obj.sys.dataset.build && obj.sys.dataset.status){
      //console.log("TRAINING PROGRESS "  + obj.sys.dataset.build)
      if(obj.sys.dataset.status == 'running'){
        progressLabel.text( "Preparing training program for " + obj.sys.dataset.build );
        if (obj.sys.dataset.data.indexOf("[DONE]") != -1){
          var val = progressbar.progressbar( "value" ) + Math.ceil(20 / (dataset_list.length) / 2);
          progressbar.progressbar( "value", val );
        }
      }

      for (i=0; i < dataset_list.length; i++){
        if(dataset_list[i].name == obj.sys.dataset.build && obj.sys.dataset.status == 'done'){
          //console.log("TRAINING DONE\n")
          dataset_list[i].state = 'training';
          socket.emit('sys', '{ "sys": { "training": { '+
          '"build": "' + obj.sys.dataset.build + '", "structure":"24", "epoch":64, "learning_rate":0.01, "filter_low":0, "filter_high":'+Math.ceil((636- Math.ceil(4400-50)*0.042))+' } } }');
        }
      }
    }

   if(obj.sys.training)
   if(obj.sys.training.build && obj.sys.training.status){

     if(obj.sys.training.status == 'running'){
       progressLabel.text( "Learning process for " + obj.sys.training.build );
       if (obj.sys.training.data.indexOf("[DONE]") != -1) {
         var val = progressbar.progressbar( "value" ) + Math.ceil(20 / (dataset_list.length) / 2);
         progressbar.progressbar( "value", val );
       }

       if( obj.sys.training.data.indexOf("classifier") != -1 ){
         console.log('ici ; ' + obj.sys.training.data)
        for (i=0; i < dataset_list.length; i++)
          if(dataset_list[i].name == obj.sys.training.build) {
            if( obj.sys.training.data.indexOf("Strong classifier") != -1 )
              dataset_list[i].state = 'built_strong';
            else if( obj.sys.training.data.indexOf("Weak classifier") != -1 )
              dataset_list[i].state = 'built_weak';
          }
        }

     }

     done = true;
     for (i=0; i < dataset_list.length; i++){
       if(dataset_list[i].name == obj.sys.training.build && obj.sys.training.status == 'done'){
         //console.log("LEARNING DONE\n")
         if (dataset_list[i].state.indexOf("built") == -1)
            dataset_list[i].state = 'error';
        }

        // If all learnings are done, close the progress bar
       if (dataset_list[i].state.indexOf('built') == -1 && dataset_list[i].name != 'Nothing.dat')
         done = false;
       }
     if (done) {
       state_learning = '';
       progressbar_win.dialog("close");
       progressbar.progressbar( "value", 0 );
     }
   }
  }

  state = "record";
  stop_record = false;
  var dataset_list = [];
  lock_loop_new = -1;
  var sample_count = -1;

  function PED_new_record  (obj){
//    console.log(JSON.stringify(obj));

    if (obj.sys.sample_count) sample_count = obj.sys.sample_count;

    if (state == "encoding" && obj.sys.records){
      document.getElementById('PED_new_progress_bar').innerHTML = "Sample encoding processing, waiting ... " + obj.sys.records.build + "<br>" ;
      if (obj.sys.records.build == new_PED && obj.sys.records.status == "done" ){
        new_PED = "";
        state = "record";
        new_PED_count = 0;
        stop_record = false;
        state = "record";
        $('#PED_new_init').show();
        $('#PED_new_progress').hide();
        //console.log("Terminated");

        socket.emit('sys', JSON.stringify({sys:{dataset:{list:''}} }));
        dialog_new.dialog('close');
        }
      }
    // If input has been reset because finised
//    if(obj.sys.sample_count == 0 && lock_loop_new > 0)
//      lock_loop_new = 0;

    if(state == "record" && obj.sys.state == 'ready'  && new_PED != ""){

      if (new_PED_count > 100 || stop_record){
        //console.log("Record Encoding");
        state = "encoding";
        socket.emit('sys', '{ "sys": { "records": { "build": "' + new_PED + '" } } }');
        socket.emit('sys', JSON.stringify( {sys:{control:'play'}} ));
        //console.log("DONE");
      }
      else if (Math.abs(obj.sys.sample_count - lock_loop_new) <= 1){

        if(obj_data.analysis.result.length == 1 &&  obj_data.analysis.result[0] == "Don t Know" && new_PED != ""){
          //console.log("save sample\n");
          socket.emit('sys', JSON.stringify( {sys:{sample: new_PED+'('+obj_data.chan+')', classe:"+"}} ));
          new_PED_count ++;
        }
        lock_loop_new = obj.sys.sample_count > lock_loop_new? obj.sys.sample_count: obj.sys.sample_count-1;
        setTimeout(function(){socket.emit('sys', JSON.stringify( {sys:{control:'next'}} ));}, 250);
      }

      else lock_loop_new = obj.sys.sample_count;
      document.getElementById('PED_new_progress_bar').innerHTML = 'Recording ... ' + new_PED + " - "+ new_PED_count +" / 100 samples<br>";
    }
  }

  function PED_update_print(){
    var list = "";
    for (var i=0; i < dataset_list.length; i++){
      if      (dataset_list[i].state == "recorded")     color = "black";
      else if (dataset_list[i].state == "training")     color = "blue";
      else if (dataset_list[i].state == "built_strong") color = "green";
      else if (dataset_list[i].state == "built_weak")   color = "orange";
      else if (dataset_list[i].state == "error")        color = "red";

      list += '<span style="color:'+color+'; margin:10px;">' + dataset_list[i].name + '</span> ';
    }

    $('#PED_lists').html(list);
  }

  function PED_update_dataset_list(obj){
    if (obj.sys.dataset)
    if(obj.sys.dataset.list){
      dataset_list = new Array();
      var list = "";
      for (var i=0; i < obj.sys.dataset.list.length; i++)
        if(dataset_list.indexOf(obj.sys.dataset.list[i]) == -1)
          dataset_list.push({name:obj.sys.dataset.list[i], state:"recorded"});
    }
  }

  socket.on('sys', function(msg){
    try {
      obj = JSON.parse(msg.toString());

      PED_new_record(obj);
      PED_build_classifier(obj);

      PED_update_dataset_list(obj);
      PED_update_print();
    }
    catch(err){
      console.log("Error on sys: " + err + " MSG received: "+ msg.toString());
    }
  });


  /******************************************************************************/
  /* Pie chart view                                                             */
  /******************************************************************************/

  var dialog = this.dialog =   $( '#PED'  ).dialog({
    autoOpen: false,
    width:650,
    modal: false,
    dialogClass: 'PED',
    buttons:{
      NEW: function(){
        dialog_new.dialog('open');
      },
      MAKE_ALL: function(){
        PED_build_classifier_init();
      },
      START_ALL:function(){
        PED_count = [['Speaker', 'Score']];
        PED_start();
      },
    }
  });


  var PED_piechart = new google.visualization.PieChart(document.getElementById('PED_piechart'));
  // Load list of recorded dataset
  setTimeout(function(){
    socket.emit('sys', JSON.stringify({sys:{dataset:{list:''}} }));
  }, 500);

  this.show = function(){
    this.dialog.dialog('open');
  }

  function updatePiechart(){
    var data = google.visualization.arrayToDataTable(PED_count);
    var options = {
      title: 'Prediction Event Distribution ',
      is3D: true,
      chartArea:{
        left:10,
        right:0, // !!! works !!!
        bottom:0,  // !!! works !!!
        top:20,
        width:"100%",
        height:"100%"
        }
    };
    PED_piechart.draw(data, options);
  }




  socket.on('sys', function(msg){

    try {
      obj = JSON.parse(msg.toString());
    }
    catch(err){
      console.log("Error on sys: " + err + " MSG received: "+ msg.toString());
    }
  });

  var obj_data = {};
  socket.on('data', function(msg){
    try {
      obj = JSON.parse(msg.toString());
      if(! obj.analysis) return;
      obj_data = obj;

      for (var i=0; i < obj.analysis.result.length; i++){
        if (obj.analysis.result[i] == '->')
          continue;
        found = false;
        for (var j =0; j < PED_count.length; j++)
          if (PED_count[j][0] == obj.analysis.result[i]){
            PED_count[j][1] += 1;
            found = true;
          }
        if (!found){
          PED_count.push([obj.analysis.result[i] , 1]);
        }
      }
    updatePiechart();
    }
    catch(err){
       console.log("Error on data: " + err + " MSG received:  "+ msg.toString());
    }
  });


  parent.innerHTML += '</div>';


}
