source ./octave/lib.m

printf("Starting");

folder_in = 'data/database/';
file_out  = 'data/dataset/default.dat';
folder_processed = 'data/processed_records/'
DEBUG     = 0;
shape_right = 0;
shape_left = 0;

arg_list = argv ();
for i = 1:nargin
  if strncmp(arg_list{i}, "--folder-in=",12)
    folder_in = arg_list{i}(13:end);
  end
  if strncmp(arg_list{i}, "--file-out=",11)
    file_out = arg_list{i}(12:end);
  end

  if strncmp(arg_list{i}, "--classe=",9)
    classe = arg_list{i}(10:end);
  end

  if strncmp(arg_list{i}, "--debug",7)
    DEBUG = 1;
  end

  if strncmp(arg_list{i}, "--shape-left=",13)
    shape_left = arg_list{i}(14:end);
  end

  if strncmp(arg_list{i}, "--shape-right=",14)
    shape_right = arg_list{i}(10:end);
  end

  if strncmp(arg_list{i}, "--filter-low=",13)
     shape_left = str2num(arg_list{i}(14:end));
  end

  if strncmp(arg_list{i}, "--filter-high=",14)
    shape_right = str2num(arg_list{i}(15:end));
  end
end

% TODO
% If already exist add it (move wav files when processed)
% if --folder-in= is not defined => Rebuild the dataset
% if --delete=NUM delete the corresponding line

try
  load(file_out)
catch
  database          = struct ();
  database.yes      = [];
  database.no       = [];
  size_data         = [];
end

printf ("\nFolder in:\t%s\nFile out:\t%s\nClasse:\t\t%s\n\n",folder_in, file_out, classe);

dirlist = dir(strcat(folder_in,'*'));
for j = 1:length(dirlist)
  if ! size(findstr(dirlist(j).name(1:end), classe),1)
    continue
  end

  if DEBUG
  printf("Processing %s\n", dirlist(j).name(1:end));
  end

  cl   = dirlist(j).name(1:1);
  chan = str2num(dirlist(j).name(findstr(dirlist(j).name(1:end), '(')+1:findstr(dirlist(j).name(1:end), ')')-1));

  [x, Fs] = auload(file_in_loadpath( strcat(folder_in, dirlist(j).name(1:end))));
  x=x(:,chan); # select only one channel
  [S, f, t] = sample_spectogram(x, Fs);
  S = S([shape_left+1:end],:);
  S = S([1:end-shape_right],:);

  size_data =  size(S);
  X = reshape(S, 1, size(S,1)*size(S,2));

  if strcmp(cl,'+')
        database.yes = [database.yes ; X];
  else
        database.no = [database.no ; X];
  end

  unix (sprintf('mv "%s" "%s"', strcat(folder_in, dirlist(j).name(1:end)), folder_processed));
end

database = setfield (database, "name", classe);
database = setfield (database, "yes", database.yes);
database = setfield (database, "no", database.no);
database = setfield (database, "size", size_data);
database = setfield (database, "shape_left", shape_left);
database = setfield (database, "shape_right", shape_right);

printf("\nClasse +: %d samples\nClasse -: %d samples\nData size: %dx%d\nshape_left:%d\nshape_right:%d", size(database.yes)(1), size(database.no)(1), size_data, database.shape_left,database.shape_right);

printf("\nSaving ...");
save('-binary', file_out, 'database');
