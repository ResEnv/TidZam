source octave/lib.m

printf("Starting");

% Init default parameters
AUTO   	= 0;
SHOW	= 0;
STREAM 	= "./tmp/sample.wav";
TIME   	= 0.5;
CHANNEL = 1;
PATH	= "./data/classifiers/";
CLASSIFIERS = [];

% Extract user parameters
arg_list = argv ();
for i = 1:nargin
	if strcmp(arg_list{i}, "--auto")
		AUTO = 1; end

	if strcmp(arg_list{i}, "--show")
		SHOW = 1; end

	if strncmp(arg_list{i}, "--stream=",9)
		STREAM = arg_list{i}(10:end); end

	if strncmp(arg_list{i}, "--time=",7)
		TIME =  str2double(arg_list{i}(8:end)) end

	if strncmp(arg_list{i}, "--channel=",10)
		CHANNEL =  str2double(arg_list{i}(11:end)) end

	if strncmp(arg_list{i}, "--classifiers-path=",19)
		PATH =  arg_list{i}(20:end) end

	if strncmp(arg_list{i}, "--classifiers=",14)
		eval( sprintf("CLASSIFIERS=%s",arg_list{i}(15:end) ) ); end

	if strncmp(arg_list{i}, "--help",6)
		printf("USAGE : predict.m --auto --show --stream={input_file} --time={analysing frequency} --channel={number_of_channel}\n");
		return;
	end
end

function [nns] = load_classifiers(folder, CLASSIFIERS)
	nns = {};
	dirlist = dir(strcat(folder,'*'));

	for i = 1:length(dirlist)
		for j=1: length(CLASSIFIERS)
			if strcmp(dirlist(i).name(1:end), CLASSIFIERS(j)) == 1
				load(strcat(folder,dirlist(i).name(1:end)));
				pos = findstr(dirlist(i).name(1:end),'-');
				pos2 = findstr(dirlist(i).name(1:end),'.');
				cl = dirlist(i).name(pos+1:pos2-1);
				nns{j} = {cl, nn};
			end
		end
	end
end

function print_conf(nns, TIME)
	global FILTER_LOW;
	global FILTER_HIGH;

  if length(nns) == 0
		printf('\n{\"classifiers\":[');

	else

	  if isfield (nns{1}{2}, "date")
		   date = nns{1}{2}.date;
		else date ='unknown';
		end
		printf("\n{\"classifiers\":[{\"name\":\"%s\", \"errors\":[%f,%f],\"structure\":\"%s\",\"roi\":\"%d-%d Hz\",\"date\":\"%s\"}",
			nns{1}{1},
			nns{1}{2}.err(1),
			nns{1}{2}.err(2),
			mat2str(nns{1}{2}.size),
			ceil(nns{1}{2}.database.shape_left/0.042+FILTER_LOW),
			ceil(FILTER_HIGH-(nns{1}{2}.database.shape_right/0.042)),
			date);
		for i=2:numel(nns)
		  if isfield (nns{i}{2}, "date")
			   date = nns{i}{2}.date;
			else date ='unknown';
			end
			printf(",{\"name\":\"%s\", \"errors\":[%f,%f],\"structure\":\"%s\",\"roi\":\"%d-%d Hz\",\"date\":\"%s\"}",
				nns{i}{1},
				nns{i}{2}.err(1),
				nns{i}{2}.err(2),
				mat2str(nns{i}{2}.size),
				ceil(nns{i}{2}.database.shape_left/0.042+FILTER_LOW),
				ceil(FILTER_HIGH-(nns{i}{2}.database.shape_right/0.042)), date);
		end
	end

	printf("], \"frequency\":%f, \"filter\":{\"high\":%d,\"low\":%d}}\n", TIME, FILTER_HIGH, FILTER_LOW );
end




function print_res(res, chan)
	fflush(stdout);
	fflush(stderr);
	printf('{"chan":%d, "analysis":', chan);

	pred = {};
	j = 1;
	for i=1:size(res,2)
		if res{i}{2} > 0.5
			pred{j} = res{i}{1};
			j = j + 1;
		end
	end

	if numel(pred) == 0
		printf("{\"result\":[\"Don't know\"], ");
	else	printf("{\"result\":[\"%s\"", pred{1}); end

	for j=2:numel(pred)
		printf(",\"%s\" ", pred{j});
	end

	if numel(pred) > 0
		printf("],");
	end

	printf('\t\t"predicitions":{');
	if length(res) > 0
			printf(' "%s": %f ', res{1}{1}, res{1}{2} );
			for i=2:size(res,2)
				printf(', \t "%s": %f', res{i}{1}, res{i}{2});
			end
	end
	printf('}}}\n');
	fflush(stdout);
	fflush(stderr);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nns = load_classifiers(PATH, CLASSIFIERS);
print_conf(nns, TIME);

% Prediction on sample
[X S f t, CHANNEL] = sample_spectogram_sound(STREAM, 1);
TIME = TIME / CHANNEL
global SIZE_WINDOW;

do
	for chan=1:CHANNEL
	try
		[X S f t, CHANNEL] = sample_spectogram_sound(STREAM, chan);
		res = {};

		v=X';
		if SHOW == 1
			visualize(v, [min(min(v)) max(max(v))], 598, 92);
			title(chan);
		else
			a = visualize(v, [min(min(v)) max(max(v))], 598, 92);
			imwrite (a, 'tmp/fft.png')
		end

		if size(X,2) < 100
			continue;
		end
		for i=1:size(nns,2)
			nns{i}{2}.testing 	= 1;

			[T window_size] =  reshape_sample(S, 598, 92, nns{i}{2}.database.shape_left, nns{i}{2}.database.shape_right);
			nns{i}{2} 		= nnff(nns{i}{2}, T, zeros(size(T,1), nns{i}{2}.size(end)));
			nns{i}{2}.testing 	= 0;


			% HACK NEW VERSION with dataset
			if strcmp(nns{i}{1},'') == 1
				nns{i}{1} = nns{i}{2}.name;
			end

			res{i}{1}		= nns{i}{1};
%			res{i}{2}		= nns{i}{2}.a{end}(1);
			res{i}{2}		= max(nns{i}{2}.a{end}(1) - 1.0*nns{i}{2}.a{end}(2),0);
%			res{i}{2}		= max( (1 + (nns{i}{2}.err(1)-nns{i}{2}.err(2))) * nns{i}{2}.a{end}(1) - (1 + (nns{i}{2}.err(2)-nns{i}{2}.err(1))) * nns{i}{2}.a{end}(2),0);


		end

		j=[];
		print_res(res, chan);

	catch err
		printf('{"Error": "%s"}\n', err.message);
	end_try_catch

	fflush(stdout);
	fflush(stderr);
	pause(TIME);
	end
until (AUTO!=1)
