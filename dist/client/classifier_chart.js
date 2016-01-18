function ClassifierChart(parent, names){

  this.selectedClass = "";

  var plots = this.plots = new Array();
  this.dialog_chart_name = "dialog-neural-outputs";
  parent.innerHTML +=
  '<div id="'+  this.dialog_chart_name +'" title="Neural Knowledge Units"></div>'+
  '<div id="dialog-info" title="Details" ></div>' +

  '<div id="dialog-database-new" title="Record database name">'+
  '<input type="text" id="dialog-database-new-input">'+
  '<input type="button" id="dialog-database-new-button" value="Create"></div>';

  var dialog_info = this.dialog_info =  $( "#dialog-info" ).dialog({
    autoOpen: false,
    modal: false,
  });

  var dialog_info_database_new = this.dialog_info_database_new =  $( "#dialog-database-new" ).dialog({
    autoOpen: false,
    width:350,
    modal: true,
  });

  $( '#dialog-database-new-button' ).click(function(){
    for (i=0; i < plots.length; i++){
      plots[i].data.addColumn('number', $( '#dialog-database-new-input' ).val());
    }
    $ ('#dialog-database-new').dialog('close');
  });

  this.dialog_info.update = function(conf){
    var print = "<table style=\"float:left;\" class=\"table_info\"><tr style=\"font-weight:bold;\"><td>Classifiers</td><td>Under Estimation</td><td>Over Estimation</td></tr>";
    for (i=0; i < conf.classifiers.length; i++)
    print += "<tr><td>"+conf.classifiers[i].name + "</td><td>" + conf.classifiers[i].errors[0] + "</td><td>" + conf.classifiers[i].errors[1] + "</td></tr>";
    print += "</table>";
    print += "<table class=\"table_info\">";
    print += "<tr><td style=\"font-weight:bold;\">Analysis frequency: </td><td> "+conf.frequency*1000+" ms</td></tr>";
    print += "<tr><td style=\"font-weight:bold;\">Filter Low Band: </td><td> "+ (conf.filter.low / 1000) +" KHz</td></tr>";
    print += "<tr><td style=\"font-weight:bold;\">Filter High Band: </td><td> "+ (conf.filter.high / 1000) +" KHz</td></tr>";
    print += "</table>";
    $( "#dialog-info" ).html(print);
  }

  var dialog = this.dialog =   $( '#dialog-neural-outputs'  ).dialog({
    autoOpen: false,
    width:600,
    modal: false,
    dialogClass: 'dialog-neural-outputs',
    buttons: {
      NEW: function(){
        $ ('#dialog-database-new').dialog('open');
      },
      YES: function(){
        cl = $('.dialog-neural-outputs .ui-button-text:contains(YES)').text().substr(4);
        socket.emit('sys', JSON.stringify( {sys:{sample: cl, classe:"+"}} ));
      },
      NO: function(){
      cl = $('.dialog-neural-outputs .ui-button-text:contains(NO)').text().substr(3);
      socket.emit('sys', JSON.stringify( {sys:{sample: cl, classe:"-"}} ));
      },
      Information: function(){
        dialog_info.dialog("open");
      }
    }
  });
  $('.dialog-neural-outputs .ui-button-text:contains(NEW)').text("New Database");
  $('.dialog-neural-outputs .ui-button-text:contains(YES)').button().hide();
  $('.dialog-neural-outputs .ui-button-text:contains(NO)').button().hide();

  this.updateSelectedClass = function(chan, item){
      this.selectedClass = item;
      $('.dialog-neural-outputs .ui-button-text:contains(YES)').text('YES '  + this.selectedClass + '('+chan+')');
      $('.dialog-neural-outputs .ui-button-text:contains(NO)').text('NO ' + this.selectedClass + '('+chan+')');
      $('.dialog-neural-outputs .ui-button-text:contains(YES)').button().show();
      $('.dialog-neural-outputs .ui-button-text:contains(NO)').button().show();
  }

  this.show = function(){
    this.dialog.dialog('open');
  }

  this.process = function(json){
    if (json.classifiers)
      this.dialog_info.update(json);

    if (json.analysis){

      // Else simple data for one channel
      var found = false;
      for (i=0; i < plots.length; i++)
      if(plots[i].name == json.chan){
        found = true;
        break;
      }
      if (!found){
        plots.push(new Chart(this, json.chan));
      }

      plots[i].updateHistory(json.analysis);
    }

    if (json.sys)
      if(json.sys.databases)
        if(obj.sys.databases.list){
        // Update legend of charts
        for (i=0; i < obj.sys.databases.list.length; i++)
          for (j=0; j < plots.length; j++){
            found = false;
            for (k=0; k < plots[j].data.getNumberOfColumns(); k++)
              if (plots[j].data.getColumnLabel(k) == obj.sys.databases.list[i])
                found = true;

              if (!found)
                plots[j].data.addColumn('number', obj.sys.databases.list[i]);
            }
        }
  }
}


/****************************************
*
/***************************************/
function Chart (parent, name) {
  this.name	= name;
  parent = this.parent = parent;
  console.log("New Channel " + this.name);

  div_charts = document.getElementById(parent.dialog_chart_name);
  var div = document.createElement('div');
  div.id = 'plot-'+this.name;
  div.class = 'plot';
  div_charts.appendChild(div);

  var data = this.data 	= new google.visualization.DataTable();
  this.data.addColumn('string', '');
  var chart = this.chart = new google.charts.Line(document.getElementById('plot-'+this.name));
  chart.chan = this.name;
  this.options 	= {
    'height':380,
    'width':'100%',
    chart: {
      title: 'Stream Channel ' + this.name,
      subtitle: 'Deep Belief Network Units'
    },
    axes: 	{
      x: {0: {side: 'bottom'}}
    },
    vAxis: {
      viewWindowMode:'explicit',
      format:"#%",
      viewWindow: {
        max:1,
        min:0
      }
    },
    displayAnnotations: true,
    legend:{textStyle:{fontSize:12, fontName:'TimesNewRoman'}}
  };

  google.visualization.events.addListener(chart, 'select', function () {
    var sel = chart.getSelection();
    if (sel.length > 0) {
      // if row is undefined, we clicked on the legend
      if (sel[0].row === null) {
        var col_name = data.getColumnLabel(sel[0].column);
        parent.updateSelectedClass(chart.chan, col_name);
      }
    }
  });

  this.num = 0;
  this.updateHistory = function(obj){
    try {
      var tmp = new Array();

      // Add column of labelled results
      var result = new String();
      for (var key in obj.result){
        result += obj.result[key] + '\n';
      }
      tmp.push(result);

      // Add column according to class prediction values
      for (var key in obj.predicitions){
        var found = false;
        for (j=0; j < this.data.getNumberOfColumns(); j++)
          if(this.data.getColumnLabel(j) == key)
            found = true;
        if(!found)
          this.data.addColumn('number', key);

        tmp.push(obj.predicitions[key]);
      }

      // Add column according database Folder


      // Complete with the expected number of column
      while (tmp.length < this.data.getNumberOfColumns())
        tmp.push(0)

      this.data.addRows([tmp]);

      if(this.data.getNumberOfRows() > 20)
      this.data.removeRow(0);

      this.chart.draw(this.data, google.charts.Line.convertOptions(this.options));
    }
    catch(err){
      console.log("[ERROR] Unable to parse JSON data: " + err);
    }
  }
}
