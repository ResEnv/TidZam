


function convertor(file)

  pos = findstr(file,'.');
  classe = substr(file, 18, pos-18);

  load (sprintf('data/saved_classifier/%s',file))

  id1 = find(sum(abs(train_y.-[1 0]),2) == 0 );
  id2 = find(sum(abs(test_y.-[1 0]),2) == 0 );

  database = struct ();
  database = setfield (database, "name", classe)
  database = setfield (database, "yes", [train_x(id1,:); test_x(id2,:)] );
  database = setfield (database, "no",  []);
  database = setfield (database, "size", [598 92]);
  database = setfield (database, "shape_left", 0);
  database = setfield (database, "shape_right", 0);

  save(sprintf('data/database/%s.dat',classe), 'database');
end

%convertor('dataset-prepared-rain.dat');
%convertor('dataset-prepared-alarm.dat');
%convertor('dataset-prepared-storm.dat');

%convertor('dataset-prepared-bird-tac.dat'); NOT WORKING ASCII TROUBLE

convertor('dataset-prepared-bird_crow.dat');
convertor('dataset-prepared-bird_plip.dat');
convertor('dataset-prepared-bird_medium.dat');
convertor('dataset-prepared-bird_whistle.dat');
