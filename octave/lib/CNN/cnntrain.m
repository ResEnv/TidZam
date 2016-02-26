function net = cnntrain(net, x, y, opts)
    m = size(x, 3)
printf("ici \n");

    numbatches = m / opts.batchsize
    if rem(numbatches, 1) ~= 0
        error('numbatches not integer');
    end
    net.rL = [];
    for i = 1 : opts.numepochs
        disp(['epoch ' num2str(i) '/' num2str(opts.numepochs)]);
        tic;
        kk = randperm(m);
        for l = 1 : numbatches
            batch_x = x(:, :, kk((l - 1) * opts.batchsize + 1 : l * opts.batchsize));
            batch_y = y(:,    kk((l - 1) * opts.batchsize + 1 : l * opts.batchsize));

printf("forward ");
            net = cnnff(net, batch_x);
printf("backpropagate  ");
            net = cnnbp(net, batch_y);
printf("applying learning   ");
            net = cnnapplygrads(net, opts);
printf("ended \n");
            if isempty(net.rL)
                net.rL(1) = net.L;
            end
            net.rL(end + 1) = 0.99 * net.rL(end) + 0.01 * net.L;
        end
        toc;
    end

end
