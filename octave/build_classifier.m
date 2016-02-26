source ./octave/lib.m

printf("Starting\n");

DEBUG     = 0;
out = "classifiers/classifier.bin";

arg_list = argv ();
SAE = 0;
DBN = 0;
CNN = 0;

structure   = '[10]';
epoch 			= 5;
learning_rate = 0.01;
shape_right = 0;
shape_left  = 0;

for i = 1:nargin
	if strncmp(arg_list{i}, "--train=",8)
		TRAIN_PATH = arg_list{i}(9:end); end

	if strncmp(arg_list{i}, "--classifier-out=",17)
		out = arg_list{i}(18:end); end

	if strncmp(arg_list{i}, "--dbn",5)
		DBN = 1; end

	if strncmp(arg_list{i}, "--sae",5)
		SAE = 1; end

	if strncmp(arg_list{i}, "--cnn",5)
		CNN = 1; end

		if strncmp(arg_list{i}, "--shape-left=",13)
		  shape_left = str2num(arg_list{i}(14:end))
		end

		if strncmp(arg_list{i}, "--structure=",12)
		  structure = eval(sprintf('[%s]',arg_list{i}(13:end)))
		end

		if strncmp(arg_list{i}, "--epoch=",8)
		  epoch = str2num(arg_list{i}(9:end))
		end

		if strncmp(arg_list{i}, "--learning_rate=",16)
		  learning_rate = str2double(arg_list{i}(17:end))
		end

	if strncmp(arg_list{i}, "--shape-right=",14)
	  shape_right = str2num(arg_list{i}(15:end))
	end

end

% =================================== DATA  ===================================
printf("Data loading ...");
load(TRAIN_PATH);
printf(" [DONE]\n");

labels  = {dataset.name,'no'};
train_x = dataset.train_x;
train_y = dataset.train_y;
test_x  = dataset.test_x;
test_y  = dataset.test_y;

printf("\nTraining set prepraration:\n");
[batchsize nb] 				= learning_compute_batchsize(train_y)
[count_by_class] 			= dataset_example_count_by_class (train_y)
[train_x] = train_x([1: batchsize*nb ],:);
[train_y]	= train_y([1: batchsize*nb ],:);
printf('Filtering train dataset (100/%d): ', size(train_x,1));
[train_x window_size] = reshape_samples(train_x, 636, 92, shape_left,shape_right);
printf('\nFiltering evaluation dataset (100/%d): ', size(train_x,1));
[test_x window_size] 	= reshape_samples(test_x, 636, 92, shape_left,shape_right);
printf(" done.\n");




id1 = find(sum(abs(train_y.-[1 0]),2) == 0 );
unlabelled = train_x; %train_x(id1,:);
[batchsize_pre nb_pre] = learning_compute_batchsize(unlabelled)
unlabelled = unlabelled([1:batchsize_pre * nb_pre],:);

size(train_x)
% ================================== LEARNING ==================================
if DBN

structure
printf("RBM Learning\n=========\n");
dbn.sizes = structure;
opts.numepochs =  epoch
opts.batchsize = batchsize_pre
opts.momentum  =   0.5;
opts.alpha     =   learning_rate;
dbn = dbnsetup(dbn, unlabelled, opts);
dbn = dbntrain(dbn, unlabelled, opts);
nn = dbnunfoldtonn(dbn, size(unlabelled,2));


printf("SAE Learning\n=========\n");
sae = saesetup([size(unlabelled,2), structure]);
for i=1:numel(sae.ae)
	sae.ae{i}.W{1} = nn.W{i};
	sae.ae{i}.W{2}(:, 2:end) = nn.W{i}'(2:end,:);

	sae.ae{i}.activation_function       			 = 'sigm';
	sae.ae{i}.learningRate              			 = 0.01;
%	sae.ae{i}.inputZeroMaskedFraction          = 0.1;
	sae.ae{i}.dropoutFraction                  = 0.5;            %  Dropout level (http://www.cs.toronto.edu/~hinton/absps/dropout.pdf)
end

opts.numepochs =   3;
opts.batchsize =  batchsize
sae = saetrain(sae, train_x, opts);

printf("NN Learning\n=========\n");
% Use the SDAE to initialize a FFNN
structure = [sae.ae{1}.size(1,1)];
for i=1: numel(sae.ae)
	structure = [structure sae.ae{i}.size(1,2)];
end
structure = [structure size(train_y, 2)]
nn = nnsetup(structure);

for i=1: numel(sae.ae)
	nn.W{i} = sae.ae{i}.W{1};
end

nn.activation_function      = 'sigm';
opts.learningRate 					= 0.01;
opts.numepochs 							=  50;
opts.batchsize 							= batchsize;


nn = nntrain(nn, train_x, train_y, opts);
[er, bad] = nntest(nn, train_x, train_y);


% ================================ VIZUALIZATION ================================
	v = dbn.rbm{1}.W';
	visualize(v, [min(min(v)) max(max(v))],window_size(1,1), window_size(1,2));

	for i=2:numel(dbn.rbm)
	  figure
		visualize(dbn.rbm{i}.W');
	end

	figure
	v = sae.ae{1}.W{1}(:,2:end)';
	visualize(v, [min(min(v)) max(max(v))],window_size(1,1), window_size(1,2))

	% Print result weight
	a = visualize(v, [min(min(v)) max(max(v))],window_size(1,1), window_size(1,2));
	pos = findstr(out,'.nn');
	out_img = out([1:pos-1]);
	imwrite (a, sprintf('%s-L1.png', out_img));
	for i=2:numel(sae.ae)
		a = visualize(sae.ae{i}.W{1}');
		imwrite (a, sprintf('%s-L%d.png', out_img, i));
	end

	v = nn.W{1}(:,2:end)';
	figure
	visualize(v, [min(min(v)) max(max(v))],window_size(1,1), window_size(1,2))


else if CNN
  train_x = double(reshape(train_x',92,92,700));
	train_y = train_y';
  test_x = double(reshape(test_x',92,92,600));
	test_y = test_y';

	rand('state',0)
	cnn.layers = {
		struct('type', 'i') %input layer
    struct('type', 'c', 'outputmaps', 24, 'kernelsize', 5) %convolution layer
    struct('type', 's', 'scale', 2) %sub sampling layer
    struct('type', 'c', 'outputmaps', 6, 'kernelsize', 5) %convolution layer
    struct('type', 's', 'scale', 2) %subsampling layer
	};

	opts.alpha = 1;
	opts.batchsize = 50;
	opts.numepochs = 10;

	cnn = cnnsetup(cnn, train_x, train_y);
	cnn = cnntrain(cnn, train_x, train_y, opts);

	[cnn.train_er, bad] = cnntest(cnn, train_x, train_y);
	[cnn.test_er, bad] = cnntest(cnn, test_x, test_y);

	save("-binary", out, "cnn");
	exit

else	printf("\n Nothing todo\n");
	printf("USAGE: train.m --train=DATASET_FILE --classifier-out=OUTPUT_FILE [--sae | --dbn | --cnn] \n");
	return
end end

% ================================== EVALUATION ==================================
printf("\nEvaluation on learning dataset \n");
nn_evaluate (nn, train_x, train_y, labels);

printf("\nEvaluation on testing dataset \n");
nn =  nn_evaluate (nn, test_x, test_y, labels);

% ==================================== SAVING ====================================
nn.database = dataset.database;
nn.database.size = window_size;
nn.database.shape_left = shape_left;
nn.database.shape_right = shape_right;
nn.labels   = labels;
nn.date			= strftime ("%X %D", localtime (time ()));
nn.epoch 		= epoch;
nn.learning_rate = learning_rate;

printf("\nSize:%dx%d\nshape_left:%d\nshape_right:%d\n", nn.database.size, nn.database.shape_left,nn.database.shape_right);

printf("\nSaving ...");
%pause
save("-binary", out,"nn");
