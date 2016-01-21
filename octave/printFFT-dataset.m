source octave/lib.m

shape_left  = 0;
shape_right = 0;

printf("Starting");

num = 0;

while 1

  if exist("set") == 1

    if num < 0
      num = 0;
    else if num > size(X,1)-1
      num = 0;
    end end

    S = X(num+1,:);

    S = reshape(S, 598,92);
    S = S([shape_left+1:end],:);
    S = S([1:end-shape_right],:);
    SIZE_WINDOW =  size(S);
    S = reshape(S, 1, size(S,1)*size(S,2));

    fflush(stdout);
    fflush(stderr);
    printf('{"dataset":{"file":"%s", "size_yes":%d, "size_no":%d, "size":"%dx%d", "num":%d}}\n', file,size(cl1,1), size(cl2,1), set.size, num);
  	fflush(stdout);
  	fflush(stderr);


    v=S';
    a = visualize(v, [min(min(v)) max(max(v))], SIZE_WINDOW(1,1),SIZE_WINDOW(1,2));
    imwrite (a, 'tmp/database-fft.png')
  end

  a = input('');
  a = strsplit (a);
  for i=1:numel(a)
    if strncmp(a{i}, "--file-in=",10)
      file = a{i}(11:end);
      load(file);
      printf('{"loading":"running"}\n');
      num = 0;
      if findstr(file,'dataset')
        cl1 = database.yes;
        cl2 = database.no;
        set = database;
      else if findstr(file,'training')
        id1 = find(sum(abs(dataset.train_y.-[1 0]),2) == 0 );
      	id2 = find(sum(abs(dataset.train_y.-[0 1]),2) == 0 );
        cl1 = dataset.train_x(id1,:);
        cl2 = dataset.train_x(id2,:);
        set = dataset;
        set.size = dataset.database.size;
      end end
      X = [cl1; cl2];
    end

    if strncmp(a{i}, "--next",6)   num ++;     end
    if strncmp(a{i}, "--prev", 6)  num --;     end

    if strncmp(a{i}, "--filter-low=",13)
      shape_left = str2num(a{i}(14:end));
    end

    if strncmp(a{i}, "--filter-high=",14)
      shape_right = str2num(a{i}(15:end));
    end
  end
endwhile
