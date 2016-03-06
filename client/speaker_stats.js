function SpeakerStats(parent, names){
  this.selectedClass = "";

  var speakers_count = [['Speaker', 'Score']];
  var plots = this.plots = new Array();
  parent.innerHTML += '<div id="speaker_stats" title="Speaker Stats"><div id="speaker_stats_piechart" style="width:600px;height:600px; text-align:center;"></div>';

// New sample for cl (if cl do not exist, it will be create)
// socket.emit('sys', JSON.stringify( {sys:{sample: cl, classe:"+"}} ));
/*
* AUTO RECORD OF NEW SPEAKER
*/
  new_speaker = "";
  new_speaker_count = 0;

  parent.innerHTML += '<div id="speaker_stats_new"> ' +
    ' <div id="speaker_stats_new_init"><input type="text" id="speaker_stats_new_value"><input type="button" value="create" id="speaker_stats_new_button"></div>' +
      '<div id="speaker_stats_new_progress"> '+
      '<div id="speaker_stats_new_progress_bar"></div>'+
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
  $('#speaker_stats_new_progress_bar').hide();

  $('#speaker_stats_new_button').on('click',function(){

    socket.emit('sys', JSON.stringify( {sys:{control:'pause'}} ));

    setTimeout( function(){
      console.log("create " + $('#speaker_stats_new_value').val());
      new_speaker = $('#speaker_stats_new_value').val();
      state == "record";
      new_speaker_count = 0;
      socket.emit('sys', JSON.stringify( {sys:{control:'next'}} ));
      }, 1000);

      $('#speaker_stats_new_init').hide();
      $('#speaker_stats_new_progress_bar').show();

  })

  var dialog_new = $("#speaker_stats_new").dialog({
    autoOpen:false,
    title:'Sample recorder',
    width:600
  });

  var html = ''

  state = "record";
  function speaker_stats_new_process  (obj){

    if (state == "encoding" && obj.sys.records){
      document.getElementById('speaker_stats_new_progress_bar').innerHTML = "Sample encoding processing, waiting ... " + obj.sys.records.build + "<br>" ;
      if (obj.sys.records.build == new_speaker && obj.sys.records.status == "done" ){
        new_speaker = "";
        state = "record";
        new_speaker_count = 0;
        state = "record";
        $('#speaker_stats_new_init').show();
        $('#speaker_stats_new_progress_bar').hide();
        console.log("Terminated");
        dialog_new.dialog('close');
        }
      }

    if(state == "record" && obj.sys.state == 'ready'  && new_speaker != ""){
      if (new_speaker_count > 10){
        console.log("Record Encoding");
        state = "encoding";
        socket.emit('sys', '{ "sys": { "records": { "build": "' + new_speaker + '" } } }');
        socket.emit('sys', JSON.stringify( {sys:{control:'play'}} ));

        console.log("DONE");
      }
      else setTimeout(function(){socket.emit('sys', JSON.stringify( {sys:{control:'next'}} ));}, 250);

      if(obj_data.analysis.result.length == 1 &&  obj_data.analysis.result[0] == "Don t Know" && new_speaker != ""){
        console.log("save sample\n");
        socket.emit('sys', JSON.stringify( {sys:{sample: new_speaker+'('+obj_data.chan+')', classe:"+"}} ));
        new_speaker_count ++;
      }
      document.getElementById('speaker_stats_new_progress_bar').innerHTML = 'Recording ... ' + new_speaker_count +" / 50 samples<br>";
    }
  }

  socket.on('sys', function(msg){
    try {
      obj = JSON.parse(msg.toString());
      speaker_stats_new_process(obj);
    }
    catch(err){
      console.log("Error on sys: " + err + " MSG received: "+ msg.toString());
    }
  });


/*
* END AUTO RECORD OF NEW SPEAKER
*/

  var dialog = this.dialog =   $( '#speaker_stats'  ).dialog({
    autoOpen: true,
    width:650,
    modal: false,
    dialogClass: 'speaker_stats',
    buttons:{
      NEW: function(){

        dialog_new.dialog('open');
      },
      BUILD: function(){

      },
      START:function(){
        speakers_count = [['Speaker', 'Score']];
      },
    }
  });

  var speaker_stats_piechart = new google.visualization.PieChart(document.getElementById('speaker_stats_piechart'));
  this.show = function(){
    this.dialog.dialog('open');
  }

  function updatePiechart(){
    var data = google.visualization.arrayToDataTable(speakers_count);
    var options = {
      title: 'Speaking Time Distribution',
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

    speaker_stats_piechart.draw(data, options);
  }




  socket.on('sys', function(msg){



    try {
      obj = JSON.parse(msg.toString());
//      speaker_stats_new_process(obj);
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
        for (var j =0; j < speakers_count.length; j++)
          if (speakers_count[j][0] == obj.analysis.result[i]){
            speakers_count[j][1] += 1;
            found = true;
          }
        if (!found){
          speakers_count.push([obj.analysis.result[i] , 1]);
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
