source octave/lib.m

shape_left  = 0;
shape_right = 0;

arg_list = argv ();
for i = 1:nargin
if strncmp(arg_list{i}, "--file-in=",10)
  file = arg_list{i}(11:end)
end
if strncmp(arg_list{i}, "--chan=",7)
  chan = str2num(arg_list{i}(8:end));
end
if strncmp(arg_list{i}, "--shape-left=",13)
  shape_left = str2num(arg_list{i}(14:end));
end

if strncmp(arg_list{i}, "--shape-right=",14)
  shape_right = str2num(arg_list{i}(10:end));
end

if strncmp(arg_list{i}, "--filter-low=",13)
  printf("here %s", arg_list{i});
  shape_left = str2num(arg_list{i}(14:end));
end

if strncmp(arg_list{i}, "--filter-high=",14)
  shape_right = str2num(arg_list{i}(15:end));
end
end

[x, Fs] = auload(file_in_loadpath( file) );
x=x(:,chan); # select only one channel

[S, f, t] = sample_spectogram(x, Fs);
S = S([shape_left+1:end],:);
S = S([1:end-shape_right],:);

SIZE_WINDOW =  size(S)


X = reshape(S, 1, size(S,1)*size(S,2));

%[X S f t, CHANNEL] = sample_spectogram_sound(, chan);
v=X';

res = {};

a = visualize(v, [min(min(v)) max(max(v))], SIZE_WINDOW(1,1),SIZE_WINDOW(1,2));
imwrite (a, 'tmp/database-fft.png')
