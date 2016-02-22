global SIZE_WINDOW = [636 92];
global FILTER_LOW = 100;
global FILTER_HIGH = 15000; % Bird between 1 - 5 Khz
warning('off','all');
addpath(genpath('octave/lib'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Predicition functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [S, f, t] =  sample_spectogram (x, Fs, FILTER_LOW, FILTER_HIGH)
	LOG=0;

	if exist("FILTER_LOW") == 0
 		global FILTER_LOW;
		global FILTER_HIGH;
	end

	step = fix(5*Fs/1000);     # one spectral slice every 5 ms
	window = fix(40*Fs/1000);  # 40 ms data window
	fftn = 2^nextpow2(window); # next highest power of 2
	[S, f, t] = specgram(x, fftn, Fs, window, window-step);
	start = ceil(fftn*FILTER_LOW/Fs);
	stop  = fftn*FILTER_HIGH/Fs;
	S = abs(S(start:stop,:)); # magnitude in range 500<f<=10 000 Hz.

	if size(S,2) < 1
		S = [];
		return
	end

	global SIZE_WINDOW;
	SIZE_WINDOW = size(S);

	S = S/max(S(:));           # normalize magnitude so that max is 0 dB.
	S = max(S, 10^(-20/10));   # clip below -20 dB.
	S = min(S, 10^(-3/10));    # clip above -3 dB.

	if LOG
		S = log(S);
		S = S/ max(max(abs(S)));
		S = abs(S);
	end
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sample_show(x)
	v=x';
	global SIZE_WINDOW;
	visualize(v, [min(min(v)) max(max(v))], SIZE_WINDOW(1,1),SIZE_WINDOW(1,2));
end

function [X S f t, channels] = sample_spectogram_sound(name_file, channel)
	addpath(genpath('Learning'));

	if exist("channel") == 0
		channel = 1;
	end

	[x, Fs] = auload(file_in_loadpath(name_file));
	channels = size(x,2);
	x=x(:,channel); # select only one channel
	[S, f, t] = sample_spectogram(x, Fs);
	X = reshape(S, 1, size(S,1)*size(S,2));
end

function [X channels] = sample_spectogram_show(name_file, channel)
	if exist("channel") == 0
		channel = 1;
	end
	[X S f t, channels] = sample_spectogram_sound(name_file, channel);
%	h = imagesc (t, f, S);
	sample_show(X);
	pos = findstr(name_file,'/');
	title_tmp = name_file(pos(size(pos,2))+1 : end);
	pos = findstr(title_tmp,'-');
	if size(pos,2) > 0
		title_start = pos(size(pos,2))+1;
	else	title_start = 1; end;
	title_tmp = title_tmp(title_start:end);
	title(title_tmp);
	colorbar
	set (gca, "ydir", "normal");
	refresh ();
end

function sample_show_class(X, Y, classe, m, labels)
	cl 		= zeros(1,size(Y,2));
	cl(classe) 	= 1;
	id = find(sum(abs(Y.-cl),2) == 0 );
	if exist("m")
		id = id(1:min(m,size(id,1)) );
	end

	figure;
	sample_show(X(id,:));

	if exist("labels")
		title(sprintf("Class: %s", labels{classe}));
	else	title(sprintf("Class: %d", classe));  end


end

function [r window_size] =  reshape_samples(v, x_ori,y_ori, x_dst,y_dst)
	r = [];
	for i=1:size(v,1)
		[t size] = reshape_sample(v(i,:), x_ori,y_ori, x_dst,y_dst);
		r = [r; t ];

		if mod(i,100) == 0
		   printf('*');
		end
	end
	window_size = size;
end

function [v window_size] =  reshape_sample(v, x_ori,y_ori, x_dst,y_dst)
%	figure
%	sample_show(v);

	v = reshape(v, x_ori, y_ori);
	v = v([x_dst+1:end],:);
	v = v([1:end-y_dst],:);
	window_size = size(v);
	v = reshape(v, 1, size(v,1)*size(v,2));

%	figure
%	visualize(v', [min(min(v)) max(max(v))], x_ori-(x_dst+y_dst-1), y_ori);
end

function [train_x train_y X test_x test_y] = reshape_samples_from_file(categ)
	global SIZE_WINDOW;
	load(sprintf("dataset/training/dataset-prepared-%s.dat", categ) );
	size(train_x)
	train_x = reshape_samples(train_x, SIZE_WINDOW(1,1), SIZE_WINDOW(1,2), 20,400); % 1 to 6 Khz
	train_x = train_x( [1: (floor(size(train_x,1) / 100)*100) ],:);
	train_y = train_y( [1: (floor(size(train_y,1) / 100)*100) ],:);
	size(train_x)

	id1 = find(sum(abs(train_y.-[1 0]),2) == 0 );
	X = train_x(id1,:);
	X = X( [1: (floor(size(X,1) / 100)*100) ],:);
	size(X)

	test_x = reshape_samples(test_x, SIZE_WINDOW(1,1), SIZE_WINDOW(1,2), 20,400);
	test_x = test_x( [1: (floor(size(test_x,1) / 100)*100) ] ,:);
	test_y = test_y( [1: (floor(size(test_y,1) / 100)*100) ] ,:);
	size(test_x)

	save(sprintf("tests/%s-179x92-data.dat",categ),"train_x","train_y","X","test_x","test_y");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dataset functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dataset_browser(x, y, id)
	if exist("id")
		[x] = dataset_get_classes(x,y,id);
	end

	for i=1:size(x,1)
		sample_show(x(i,:));
		pause
	end
end

% Simple randomization
function [x y] = dataset_random(x, y)

id1 = ceil(rand(size(y,1), 1) * size(y,1));
id2 = ceil(rand(size(y,1), 1) * size(y,1));

tmp_x = x(id1,:);
tmp_y = y(id1,:);

x(id1,:) = x(id2,:);
y(id1,:) = y(id2,:);

x(id2,:) = tmp_x;
y(id2,:) = tmp_y;
end

% Randomize the training dataset with alternation between each class
% In: A training dataset
% Out: Randomized training dataset
function [res_x res_y] = dataset_random_ordered(x, y)
	printf("Randomization and class alternation of %d samples over %d classes: ", size(y,1), size(y,2));
	% Extract examples by class and select a random list of them
	X = {};
	for i=1:size(y,2)
		X_t = dataset_get_classes(x,y,i);
		X{i}{1} = X_t;
		X{i}{2} = ceil(rand(  size(X{i}{1},1) ,1) *size(X{i}{1},1)    );
	end

	% Generate result dataset by alterning examples of each class
	res_x = res_y = [];
	for i=1:size(y,1) % For each example
		for j=1:size(X,2) % For each class
			if size(X{j}{2},1) > i
				res_x = [ res_x; X{j}{1}( X{j}{2}(i), :) ];
				classe 		= zeros(1,size(y,2));
				classe(j) 	= 1;
				res_y = [res_y; classe];
			else
				printf(" [DONE]\n");
				return
			end
		end
		if mod(i,100) == 0
			printf("*");
		end
	end
end

% Return the number of elements in each class contained in dataset Y
% In: dataset Y
% Out: Vector of number of elements by class
function count = dataset_example_count_by_class (Y)
	nb_class = size(Y,2);

	count = [];
	for i=1:nb_class
		classe 		= zeros(1,nb_class);
		classe(i) 	= 1;
		count = [count, size(find(sum(abs(Y.-classe),2) == 0 ),1)];
	end
end

% Return the different examples of the class id of input dataset
% In: Training dataset
% Out: Examples of class id
function [X] = dataset_get_classes(X, Y, id)
	classe 		= zeros(1,size(Y,2));
	classe(id) 	= 1;
	res = find(sum(abs(Y.-classe),2) == 0 );
	X = X(res,:);
end

% Separate each class contained in train dataset into several dataset files
% In: train_x, train_y, labels
% Out : dataset files in dst folder
function dataset_split_classes_into_files(train_x, train_y, labels, dst)
	for i=1:size(labels,2)
		printf("Label: %s ", labels{i});
		[X] = dataset_get_classes(train_x, train_y, i);
		save(sprintf("%s/dataset-%s.dat",dst,labels{i}), "X");
		printf("\t (%d samples)\t [DONE]\n", size(X,1));
	end
end

% Generate a new binary dataset of one class and the others
% In: Folder containing the set of class dataset files
% Out: The binary dataset for the class training
function [train_x train_y labels] = dataset_binary_build_from_training_files(src, class, out)
	dirlist = dir(strcat(src,'*'));
	dirlist_out = dir(strcat(out,'*'));
	train_x = train_y = [];

	% If already prepared, exist
	for j = 1:length(dirlist_out)
		if size(findstr(dirlist_out(j).name(1:end),'prepared'),1) > 0 && size(findstr(dirlist_out(j).name(1:end),class),1) > 0
			return
		end
	end

	for i = 1:length(dirlist)
		if size(findstr(dirlist(i).name(1:end),'prepared'),1) > 0 % It is not a brut dataset
			continue
		end

		pos = findstr(dirlist(i).name(1:end),'-');
		cl = dirlist(i).name(pos+1:end-4);

		load(strcat(src,dirlist(i).name(1:end)));
		train_x = [train_x; X];
		if strcmp(class,cl)
			train_y = [train_y; ones(size(X,1),1) zeros(size(X,1),1) ];
		else
			train_y = [train_y; zeros(size(X,1),1) ones(size(X,1),1) ];
		end
	end
	labels{1} = class;
	labels{2} = "none";
end

% Split the training dataset into training and test dataset
% In: Training datasets
% Out: Training and test datasets
function [train_x train_y test_x test_y labels] = dataset_split_into_training_test(X, Y, labels_t, p, m)
	if exist("p") == 0
		p = 0.7;
	end

	if exist("m") == 0
		m = 10;
	end

	labels = {};
	train_x = train_y = test_x = test_y = train_y_t = test_y_t = [];

	nb_class = size(Y,2);
	size_by_class = ceil(max( min(dataset_example_count_by_class (Y)), m ) * p);

	if size_by_class < m
		printf("(Not enough samples for each class) ");
		return;
	end

	[X Y] = dataset_random(X, Y);

	id1 = find(sum(abs(Y.-[1 0]),2) == 0 );
	id2 = find(sum(abs(Y.-[0 1]),2) == 0 );

	nb_ex 	= floor(size(id1,1) * p);

	for i=1:ceil(size(Y,1) * p / size(id1,1) )
		if ((i+1)*nb_ex > size(id2,1))
		printf("ici");
			break;
		end;

		printf("*");
		train_x = [train_x; X( id1(1:nb_ex), :) ];
		train_y = [train_y; [ones(nb_ex,1) zeros(nb_ex,1)] ];

		train_x = [train_x; X( id2( (i-1)*nb_ex+1 : i*nb_ex), :) ];
		train_y = [train_y; [zeros(nb_ex,1) ones(nb_ex,1)] ];
	end

	test_x = [
		X(id1(nb_ex:end),:);
		X(id2(i*nb_ex + 1:end),:)
		];
	test_y = [
		[ ones( size(X( id1(nb_ex:end), :) ,1), 1)  zeros( size(X(id1(nb_ex:end),:),1), 1) ];
		[ zeros( size(X( id2( i*nb_ex+1:end), :), 1), 1) ones( size(X( id2( i*nb_ex+1:end), :), 1), 1)]
		];

labels = labels_t;
printf("\n#samples %d/%d -> training %d samples and testing %d samples\n", nb_ex,size(Y,1), size(train_y,1), size(test_y,1) );

[train_x train_y] = dataset_random_ordered(train_x, train_y);
return
	% Add examples on all class
	for i=1:nb_class
		printf("*");
		classe 		= zeros(1,nb_class);
		classe(i) 	= 1;
		id = find(sum(abs(Y.-classe),2) == 0 );
		if size(id,1) > m-1
			train_x = [train_x; X(id(1:size_by_class),:)];
			train_y_t = [train_y_t; Y(id(1:size_by_class),:)];

			test_x = [test_x; X(id(size_by_class:end),:)];
			test_y_t = [test_y_t; Y(id(size_by_class:end),:)];
		end
	end

	% Artificial increasing of dataset woth the same first class and new second class
	if size(test_y_t,1) > 0
		classe = [1 0];
		id1 = find(sum(abs(train_y_t.-classe),2) == 0 );
		classe = [0 1 ];
		id = find(sum(abs(Y.-classe),2) == 0 );

		for i=1:floor(size(Y,1)*p/size(id1,1))
			printf("x");
			train_x = [train_x; train_x(id1,:)];
			train_y_t = [train_y_t; train_y_t(id1,:)];

			batchsize = size(id1,1);
			id_t = id(i*batchsize: min(batchsize*(i+1),size(id,1) ));
			train_x = [train_x; X(id_t,:)];
			train_y_t = [train_y_t; Y(id_t,:)];
		end
		printf("\t");

		[train_x train_y_t] = dataset_random_ordered(train_x, train_y_t);
	end

	% Delete empty classe
	j=1;
	for i=1:nb_class
		if sum(train_y_t(:,i)) != 0
			train_y = [train_y train_y_t(:,i)];
			test_y = [test_y test_y_t(:,i)];
			labels{j++} = labels_t{i};
		end
	end
end

% Get all labelled datasets in src folder and generated binary datasets for each class
% m : minimal number of examples to generate the binary dataset for each class
% p : ratio between training and test samples in the binary datasets
function dataset_generate_binary_training (src, dst, p, m)
	dirlist = dir(strcat(src,'*'));
	for i = 1:length(dirlist)
		if size(findstr(dirlist(i).name(1:end),'prepared'),1) > 0
			continue;
		end

		pos = findstr(dirlist(i).name(1:end),'-');
		cl = dirlist(i).name(pos+1:end-4);
		printf("Class %s\t ", cl);
		[train_x train_y labels] = dataset_binary_build_from_training_files(src, cl, dst);
		if size(train_x,1) == 0
			printf("[ALREADY DONE]\n");
			continue;
		end
		labels{1} = cl;
		labels{2} = "none";
		[train_x train_y test_x test_y labels] = dataset_split_into_training_test(train_x, train_y, labels, p, m);
		printf("\t");

		if size(train_y,2) != 2 % If there was not enough example
			printf("[FAILED]\n");
		else
			classe = [1 0];
			id_train = find(sum(abs(train_y.-classe),2) == 0 ); % If there was not example in one class
			id_test = find(sum(abs(test_y.-classe),2) == 0 ); % Or in the other
			printf("(train %d / %d samples  ; test %d / %d samples)\n", size(id_train,1), size(train_y,1) , size(id_test,1), size(test_y,1)  );
			save(sprintf("%s/dataset-prepared-%s.dat", dst, cl), "train_x", "train_y", "test_x","test_y", "labels");
			printf("Saved in %s/dataset-prepared-%s.dat\n\n", dst, cl);
		end
	end
end

% Get the brut dataset file in src and generate the binary dataset for each class
% In: Brut dataset file in src
% Out: Folder to save the binary dataset for each class named -prepared
function dataset_build(dst, dst_prepared, src, p, m)
	if exist("p") == 0
		p = 0.7;
	end

	if exist("m") == 0
		m = 20;
	end
	if exist("src") == 1
		printf("===================\n");
		printf("Build label dataset\n");
		printf("===================\n");
		load(src);
		dataset_split_classes_into_files(train_x, train_y, labels, dst);
	end

	printf("\n===================\n");
	printf("Build class dataset\n");
	printf("===================\n");
	dataset_generate_binary_training (dst, dst_prepared, p, m);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate an unlabelled dataset X from wav file contained in folder
% In: Folder containing the wav files
% Out: The unlabelled dataset
function [X] =  dataset_generate_unlabelled (folder, dest)

	dirlist = dir(strcat(folder,'*'));
	X = [];
	for i = 1:length(dirlist)
		name_file = strcat(folder,"/",dirlist(i).name(1:end));
		[x, Fs] = auload(file_in_loadpath(name_file));
		x=x(:,1);

		if (size(x,1) < 2 || size(x,2) < 1)
			continue;
		end
		[S, f, t] = sample_spectogram(x, Fs);
		if (size(S,1) < 1 || size(S,2) < 1)
			printf("Spectogram error: drop example\n");
		end
		S = reshape(S, 1, size(S,1)*size(S,2));
		X = [X; S];
		if mod(i,100) == 0
			printf("Samples %d DONE ...\n", i);
		end
	end
	if exist("dest")
		save(dest,"X");
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% training_labelled : Generate a labelled data set [X,Y]
%                       folder : folder source of wav samples (stuff-y1-y2-y3.wav)
%                       dest : Optional destination file to save dataset
function [X Y labels] = dataset_generate_labelled(folder, dest)
	X = [];
	Y = [];
	labels = {};

	addpath(genpath('Preprocessing'));
	dirlist = dir(strcat(folder,'*'));

	for i = 1:length(dirlist)
		% Get position of classe strings
		pos = findstr(dirlist(i).name(1:end),'-');

		if size(pos,2) < 1
			# Skip if unlabelled
			continue;
		end;

		y = zeros(1,size(Y,2));
		for k=1:numel(pos)
			% Get the classe names
			if k < numel(pos)
				classe = dirlist(i).name(pos(k)+1:pos(k+1));
			else
				% The last one
				classe = dirlist(i).name(pos(k)+1:end-4);
			end

			% Build classe vector
			done = false;
			for j=1:numel(labels)
				if strcmp(labels{j}, classe)
					y(j) = 1;
					done = true;
				end
			end

			% Create classe if it does not exist
			if done == false
				labels{numel(labels)+1} = classe;
				y = [ y 1 ];

			end
		end

		% Add a zero column for each new detected classes
		Y = [Y, zeros( size(Y,1), size(y,2) - size(Y,2))];

		% Add sample in dataset
		Y = [Y; y];

		name_file = strcat(folder,"/",dirlist(i).name(1:end))
		[x, Fs] = auload(file_in_loadpath(name_file));
		x=x(:,1); # select only one channel
		#auplot(x,Fs);
		[S, f, t] = sample_spectogram(x, Fs);
		S = reshape(S, 1, size(S,1)*size(S,2));
		X = [X; S];
	end;


	% Randomize data
	for i=1:size(X,1)
		j = ceil(rand()*size(X,1));
		k = ceil(rand()*size(X,1));

		tmp = X(j,:);
		X(j,:) = X(k,:);
		X(k,:) = tmp;

		tmp = Y(j,:);
		Y(j,:) = Y(k,:);
		Y(k,:) = tmp;
	end

	if exist("dest")
		save(dest,"X","Y","labels");
	end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Learning functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [batchsize nb] = learning_compute_batchsize(Y)
	batchsize = 100;

	do
		nb = floor(size(Y,1)/batchsize);

		if nb > 20
			return
		end
		batchsize = floor(batchsize / 2);

	until 1

end

function [nn sae] = learning_sae(train_x, unlabelled, train_y, archi, epoch, learningRate, mask)
	if exist("batchsize") == 0
		batchsize = size(train_x,1);
	end

	if exist("rate") == 0
		learningRate = 1;
	end

	if exist("mask") == 0
		mask = 0.5;
	end

	if exist("epoch") == 0
		epoch = 1;
	end

	printf("SAE Learning\n=========\n");
	rand('state',0);
	[batchsize nb] = learning_compute_batchsize(unlabelled);
	sae = saesetup([size(train_x,2), archi]);
	sae.ae{1}.activation_function       = 'sigm';
	sae.ae{1}.learningRate              = learningRate;
	sae.ae{1}.inputZeroMaskedFraction   = mask;
	opts.numepochs =   1;
	opts.batchsize =  batchsize

	sae = saetrain(sae, train_x, opts);

	printf("NN Learning\n=========\n");
	rand('state',0)
	[batchsize nb] = learning_compute_batchsize(train_y);
	[nn] = learning_nn(sae, train_x,train_y, epoch, batchsize, 1);
end

function [nn sae dbn] = learning_dbn(train_x, unlabelled, train_y, archi, epoch, alpha, momentum)
	rand('state',1)
	dbn.sizes = archi;
	if exist("epoch") == 0
		epoch = 1;
	end
	if exist("alpha") == 0
		alpha = 0.9;
	end
	if exist("momentum") == 0
		momentum = 0.25;
	end
	rand('state',1);
	[batchsize nb] = learning_compute_batchsize(unlabelled);

	archi
	printf("RBM Learning\n=========\n");
	dbn.sizes = archi;
	opts.numepochs =  epoch;
	opts.batchsize = batchsize;
	opts.momentum  =   momentum;
	opts.alpha     =   alpha;
	dbn = dbnsetup(dbn, unlabelled, opts);
	dbn = dbntrain(dbn, unlabelled, opts);
	nn = dbnunfoldtonn(dbn, size(unlabelled,2));


  printf("SAE Learning\n=========\n");
	sae = saesetup([size(unlabelled,2), archi]);
	for i=1:numel(sae.ae)
		sae.ae{i}.W{1} = nn.W{i};
%		sae.ae{i}.inputZeroMaskedFraction          = 0.1;
%		sae.ae{i}.dropoutFraction                  = 0.5;            %  Dropout level (http://www.cs.toronto.edu/~hinton/absps/dropout.pdf)
	end

	sae.ae{1}.activation_function       = 'sigm';
	sae.ae{1}.learningRate              = 0.01;
	sae.ae{1}.inputZeroMaskedFraction   = 0.5;
	opts.numepochs =   1;
	opts.batchsize =  batchsize

	sae = saetrain(sae, train_x, opts);

	printf("NN Learning\n=========\n");
	[nn] = learning_nn(sae, train_x,train_y, 30, batchsize, 0.01);

return

	%?	[nn] = dbnunfoldtonn(dbn, size(train_y,2));
	nn.activation_function = 'sigm';

%	nn.activation_function              = 'tanh_opt';   %  Activation functions of hidden layers: 'sigm' (sigmoid) or 'tanh_opt' (optimal tanh).
%	nn.learningRate                     = 2;            %  learning rate Note: typically needs to be lower when using 'sigm' activation function and non-normalized inputs.
%	nn.momentum                         = 0.5;          %  Momentum
%	nn.scaling_learningRate             = 0.9;            %  Scaling factor for the learning rate (each epoch)
%	nn.weightPenaltyL2                  = 0;            %  L2 regularization
%	nn.nonSparsityPenalty               = 0.1;            %  Non sparsity penalty
%	nn.sparsityTarget                   = 0.05;         %  Sparsity target
%	nn.inputZeroMaskedFraction          = 0.1;            %  Used for Denoising AutoEncoders
%	nn.dropoutFraction                  = 0.25;            %  Dropout level (http://www.cs.toronto.edu/~hinton/absps/dropout.pdf)

	[batchsize nb] = learning_compute_batchsize(train_y);
	opts.numepochs =  30;
	opts.batchsize = batchsize;
	nn = nntrain(nn, train_x, train_y, opts);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [nn er bad] = learning_nn(sae, train_x,train_y, epoch, batchsize, learningRate);
	if exist("batchsize") == 0
		batchsize = size(train_x,1);
	end

	if exist("rate") == 0
		learningRate = 1;
	end

	% Use the SDAE to initialize a FFNN
	archi = [sae.ae{1}.size(1,1)];
	for i=1: numel(sae.ae)
		archi = [archi sae.ae{i}.size(1,2)];
	end
	archi = [archi size(train_y, 2)]

	nn = nnsetup(archi);
	nn.activation_function              = 'tanh_opt';   %  Activation functions of hidden layers: 'sigm' (sigmoid) or 'tanh_opt' (optimal tanh).
	nn.learningRate                     = 2;            %  learning rate Note: typically needs to be lower when using 'sigm' activation function and non-normalized inputs.
	nn.momentum                         = 0.5;          %  Momentum
	nn.scaling_learningRate             = 0.9;            %  Scaling factor for the learning rate (each epoch)
	nn.weightPenaltyL2                  = 0;            %  L2 regularization
	nn.nonSparsityPenalty               = 0.1;            %  Non sparsity penalty
	nn.sparsityTarget                   = 0.05;         %  Sparsity target
	nn.inputZeroMaskedFraction          = 0.1;            %  Used for Denoising AutoEncoders
	nn.dropoutFraction                  = 0.25;            %  Dropout level (http://www.cs.toronto.edu/~hinton/absps/dropout.pdf)

	for i=1: numel(sae.ae)
		nn.W{i} = sae.ae{i}.W{1};
	end

	%train nn
	if exist("epoch") == 0
		epoch = 100;
	end
	opts.numepochs =  epoch;
	opts.batchsize = batchsize;
	nn = nntrain(nn, train_x, train_y, opts);
	[er, bad] = nntest(nn, train_x, train_y);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nn bad] = nn_evaluate (nn, x, y, labels)
	[er, bad] = nntest(nn, x, y);
	errors = zeros(1,size(labels,2));
	A = y(bad,:);
	for i=1:size(A,1)
		errors(find(A(i,:)==1)) = errors(find(A(i,:)==1)) + 1;
	end

	total = dataset_example_count_by_class (y);
	printf("Global error %f :\n=======================\n", er);
	nn.err = [];
	for i=1:size(labels,2)
		nn.err = [nn.err; double(errors(i)) / double(total(i))];
		printf("%s: %f (%d)\n", labels{i}, nn.err(i), total(i) );
	end
	printf("=======================\n\n");
end
