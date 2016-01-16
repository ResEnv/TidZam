source octave/lib.m
arg_list = argv ();
for i = 1:nargin
if strncmp(arg_list{i}, "--file-in=",10)
  file = arg_list{i}(11:end);
end
if strncmp(arg_list{i}, "--chan=",7)
  chan = str2num(arg_list{i}(8:end));
end
end


[X S f t, CHANNEL] = sample_spectogram_sound(file, chan);
res = {};

v=X';
a = visualize(v, [min(min(v)) max(max(v))], SIZE_WINDOW(1,1),SIZE_WINDOW(1,2));
imwrite (a, 'tmp/database-fft.png')
