source ./octave/lib.m

printf("Starting\n");

folder_in = 'data/dataset/';
file_out  = 'data/training/default.dat';
size_min  = 1000;
DEBUG     = 0;
p = 0.7

arg_list = argv ();
for i = 1:nargin
  if strncmp(arg_list{i}, "--file-in=",10)
    file_in = arg_list{i}(11:end);
  end
  if strncmp(arg_list{i}, "--file-out=",11)
    file_out = arg_list{i}(12:end);
  end

  if strncmp(arg_list{i}, "--size-min=",11)
    size_min = arg_list{i}(12:end);
  end

  if strncmp(arg_list{i}, "--extraction-rate=",18)
    p = arg_list{i}(19:end);
  end

  if strncmp(arg_list{i}, "--debug",7)
    DEBUG = 1;
  end
end

dataset = struct ();
dataset.name =  file_in(1:findstr(file_in, '.dat')-1);


% LOADING DATABASES
dirlist = dir(strcat(folder_in,'*'));
others = [];
printf("\nLoading dataset (%s):\n",strcat(folder_in,'*'));

load(sprintf("%s%s.dat",folder_in,dataset.name ))

if exist('database') == 0
    printf("loading failed\n");
end

printf('=> %s\n', database.name);
current = database;


dataset.database = {};
dataset.database.name         = database.name;
dataset.database.used         = [];
dataset.database.size         = current.size;
dataset.database.yes_size     = size(current.yes,1);
dataset.database.no_size      = size(current.no,1);
dataset.database.shape_left   = current.shape_left;
dataset.database.shape_right  = current.shape_right;

for j = 1:length(dirlist)
  load (sprintf("%s%s",folder_in, dirlist(j).name(1:end)));
  if strcmp(database.name, dataset.name) == 0
  current.size
  database.size
  database.name
    if (current.size == database.size)
      printf('* %s (%d)\n', database.name, size(database.yes,1));
      others = [others; database.yes];
      dataset.database.used = [ dataset.database.used, database.name];
    end
  end
end

printf("\nDataset generation for %s\n", dataset.name);
X = [];
X = current.yes;
Y = [ones(size(current.yes,1),1) zeros(size(current.yes,1),1)];
printf("Available positive: %d samples\n", size(X,1));
X = [X; current.no];
Y = [Y; zeros(size(current.no,1),1) ones(size(current.no,1),1)];
printf("Available negative: %d samples\n", size(current.no,1));

if size(X,1) == 0
  printf("No sample found.\n");
  exit(0);
end

printf("\nDataset preparation:\n");
while (size(X,1) < size_min / 2)
  X = [X; current.yes];
  Y = [Y; [ones(size(current.yes,1),1) zeros(size(current.yes,1),1)]];
endwhile
printf("* %d samples generated from %s.\n", size(X,1), dataset.name);
nop = ceil(rand( size_min - size(X,1), 1) * size(others,1));
nop = others(nop,:);
X = [X; nop];
Y = [Y; zeros(size(nop,1),1) ones(size(nop,1),1)];
printf("* %d samples added from other datasets.\nTotal: %d samples.\n", size(nop,1), size(X,1));

printf("\nDataset Randomization: ");
id1 = ceil(rand(size(X,1),1) * size(X,1));
id2 = ceil(rand(size(X,1),1) * size(X,1));
tx  = X(id1,:);
ty  = Y(id1,:);
X(id1,:) = X(id2,:);
Y(id1,:) = Y(id2,:);
X(id2,:) = tx;
Y(id2,:) = ty;
printf("done.\n")

printf("\nEvaluation Dataset Extraction:\n");
dataset.train_x = X([1:size(X,1)*p], :);
dataset.train_y = Y([1:size(X,1)*p], :);
dataset.test_x = X([size(X,1)*p+1:end], :);
dataset.test_y  = Y([size(X,1)*p+1:end], :);

printf("Train Dataset: %d samples\n Test Dataset: %d samples\nSize:%dx%d\n", size(dataset.train_x,1), size(dataset.test_x,1), dataset.database.size);

printf("\nSaving ...");
save ("-binary", file_out,  "dataset");
