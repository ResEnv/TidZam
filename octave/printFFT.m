source octave/lib.m

shape_left  = 0;
shape_right = 0;

printf("Starting");

arg_list = argv ();
for i = 1:nargin
if strncmp(arg_list{i}, "--file-in=",10)
  file = arg_list{i}(11:end);
end

% FOR DATASET FILE
if strncmp(arg_list{i}, "--num=",6)
  num = str2num(arg_list{i}(7:end));
end

% FOR AUDIO FILE
if strncmp(arg_list{i}, "--chan=",7)
  chan = str2num(arg_list{i}(8:end));
end
if strncmp(arg_list{i}, "--shape-left=",12)
  shape_left = str2num(arg_list{i}(13:end));
end

if strncmp(arg_list{i}, "--shape-right=",13)
  shape_right = str2num(arg_list{i}(14:end));
end

if strncmp(arg_list{i}, "--filter-low=",13)
  shape_left = str2num(arg_list{i}(14:end));
end

if strncmp(arg_list{i}, "--filter-high=",14)
  shape_right = str2num(arg_list{i}(15:end));
end
end
if length(findstr(file, 'wav')) > 0
  printf('{"record":{"file": "%s"}}"\n', file);
  [x, Fs] = auload(file_in_loadpath( file) );
  x=x(:,chan); # select only one channel
  [S, f, t] = sample_spectogram(x, Fs);

  shape_left
  size(S)

  S = S([shape_left+1:end],:);
  S = S([1:end-shape_right],:);
  SIZE_WINDOW =  size(S);
  X = reshape(S, 1, size(S,1)*size(S,2));

else if length(findstr(file, 'dataset')) > 0 && length(findstr(file, 'dat')) > 0
  load(file);
  % TODO : load all classes and print their label on picture
  X = [database.yes; database.no];
  X = X(num+1,:);

  S = reshape(X, 638,92);
  S = S([shape_left+1:end],:);
  S = S([1:end-shape_right],:);
  SIZE_WINDOW =  size(S);
  X = reshape(S, 1, size(S,1)*size(S,2));
  printf('{"dataset":{"file":"%s", "size_yes":%d, "size_no":%d, "size":"%dx%d", "num":%d}}\n', file,size(database.yes,1), size(database.no,1), database.size, num);

else if length(findstr(file, 'training')) > 0 && length(findstr(file, 'dat')) > 0
  load(file);
  % TODO : load all classes and print their label on picture
  X = dataset.train_x(num+1,:);
  SIZE_WINDOW = database.size;
  id1 = find(sum(abs(dataset.train_y.-[1 0]),2) == 0 );
  id2 = find(sum(abs(dataset.train_y.-[0 1]),2) == 0 );
  printf('{"trainer":{"file":"%s", "size_yes":%d, "size_no":%d, "size":"%dx%d"}}\n', file, size(id1,1), size(id2,1), dataset.database.size);
else
  printf('{"error":"Error Input File"}');
  exit;
end
end
end

v=X';
a = visualize(v, [min(min(v)) max(max(v))], SIZE_WINDOW(1,1),SIZE_WINDOW(1,2));
imwrite (a, 'tmp/database-fft.png')
