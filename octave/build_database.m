source ./octave/lib.m

printf("Starting");

folder_in = 'data/database/';
file_out  = 'data/dataset/default.dat';
DEBUG     = 0;

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
end

printf ("\nFolder in:\t%s\nFile out:\t%s\nClasse:\t\t%s\n\n",folder_in, file_out, classe);

cl1       = [];
cl2       = [];
size_data = [];
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
  size_data =  size(S);
  X = reshape(S, 1, size(S,1)*size(S,2));

  if strcmp(cl,'+')
        cl1 = [cl1 ; X];
  else
        cl2 = [cl2 ; X];
  end

end
database = struct ();
database = setfield (database, "name", classe);
database = setfield (database, "yes", cl1);
database = setfield (database, "no", cl2);
database = setfield (database, "size", size_data);


save(file_out, '-binary', 'database');
printf("\nClasse +: %d samples\nClasse -: %d samples\nData size: %dx%d\n\n", size(cl1)(1), size(cl2)(1), size_data);
