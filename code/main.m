clear;
time_start = clock;
% hyper-parameters
filename = 'nocolor/bunny';
pcname = [filename, '.ply'];
alpha = 0.1;
lambda = 1.9e-7;
eta = 0.05;
K = 15;
p_thres_min = 3000;
p_thres_max = 8000;
simpname = [filename, '-sr', num2str(alpha),...
			'-cp', num2str(lambda), '.ply'];

% load the point cloud
pc = pcread(pcname);
X = double(pc.Location);
if ~isempty(pc.Color)
    X = [X, double(pc.Color)];
end
n = pc.Count;
range = [pc.XLimits; pc.YLimits; pc.ZLimits];
clear pc;
disp(['n: ',num2str(n)]);

% divide the point cloud into grids
GRID_NUM = round(n/p_thres_min);
VOLUMN = prod(range(:,2)-range(:,1));
GRID_LEN = nthroot(VOLUMN/GRID_NUM,3);
GRID_NUM = ceil((range(:,2)-range(:,1))/GRID_LEN);
GRID_LEN = (range(:,2)-range(:,1))./GRID_NUM;
sigma = nthroot(VOLUMN/n,3)^2;
% simplify while dividing
m = 0;
simpX = zeros(round(alpha*n), size(X,2));
for i = 1:GRID_NUM(1)
    x_min = range(1,1)+GRID_LEN(1)*(i-1);
    x_max = x_min+GRID_LEN(1);
    GRID_DELTA = GRID_LEN(1)*0.1;
    % overlapping
    tmpi = X(X(:,1)>x_min-GRID_DELTA & X(:,1)<x_max+GRID_DELTA, :);
    xst = 0;
    xed = 0;
    % for floating point comparing (==)
    if i == 1
    	xst = 1e-5;
    end
    if i == GRID_NUM(1)
    	xed = 1e-5;
    end
    for j = 1:GRID_NUM(2)
        y_min = range(2,1)+GRID_LEN(2)*(j-1);
        y_max = y_min+GRID_LEN(2);
        GRID_DELTA = GRID_LEN(2)*0.1;
        % overlapping
        tmpj = tmpi(tmpi(:,2)>y_min-GRID_DELTA & tmpi(:,2)<y_max+GRID_DELTA, :);
		yst = 0;
	    yed = 0;
	    % for floating point comparing (==)
	    if j == 1
	    	yst = 1e-5;
        end
	    if j == GRID_NUM(2)
	    	yed = 1e-5;
	    end
        for k = 1:GRID_NUM(3)
            z_min = range(3,1)+GRID_LEN(3)*(k-1);
            z_max = z_min+GRID_LEN(3);
            GRID_DELTA = GRID_LEN(3)*0.1;
            % overlapping
            tmpk = tmpj(tmpj(:,3)>z_min-GRID_DELTA & tmpj(:,3)<z_max+GRID_DELTA, :);
            zst = 0;
		    zed = 0;
		    % for floating point comparing (==)
		    if k == 1
		    	zst = 1e-5;
            end
		    if k == GRID_NUM(3)
		    	zed = 1e-5;
		    end
            % simplify
            disp([' simplifying in ', num2str(i), num2str(j), num2str(k)]);
            if size(tmpk, 1) > p_thres_max
            	% divide again
            	[deep_grid, deep_grid_num] = divide(tmpk, p_thres_min);
            	for p = 1:deep_grid_num
            		tmp = simplify(alpha, lambda, sigma, eta, K, deep_grid(p).X);
            		deep_range = deep_grid(p).range;
            		deep_edge = deep_grid(p).edge;
		        	tmp = tmp(tmp(:,1)>deep_range(1,1)-xst*deep_edge(1,1)...
		        			& tmp(:,1)<deep_range(1,2)+xed*deep_edge(1,2), :);
		        	tmp = tmp(tmp(:,2)>deep_range(2,1)-yst*deep_edge(2,1)...
		        			& tmp(:,2)<deep_range(2,2)+yed*deep_edge(2,2), :);
		        	tmp = tmp(tmp(:,3)>deep_range(3,1)-zst*deep_edge(3,1)...
		        			& tmp(:,3)<deep_range(3,2)+zed*deep_edge(3,2), :);
		        	t = size(tmp,1);
                    if t > 0
					    simpX(m+1:m+t, :) = tmp;
					    m = m + t;
                    end
            	end
            	clear deep_grid;
            else
            	tmp = simplify(alpha, lambda, sigma, eta, K, tmpk);
            	tmp = tmp(tmp(:,1)>x_min-xst & tmp(:,1)<x_max+xed, :);
            	tmp = tmp(tmp(:,2)>y_min-yst & tmp(:,2)<y_max+yed, :);
            	tmp = tmp(tmp(:,3)>z_min-zst & tmp(:,3)<z_max+zed, :);
                t = size(tmp,1);
                if t > 0
				    simpX(m+1:m+t, :) = tmp;
				    m = m + t;
                end
            end	            
        end
    end
end

% save the simplifxed point cloud
disp(['m: ',num2str(m)]);
if size(X,2) == 3
    pc = pointCloud(simpX(1:m,:));
else % == 6
    pc = pointCloud(simpX(1:m,1:3),'Color',simpX(1:m,4:6));
end
pcwrite(pc,simpname,'PLYFormat','binary');

time_end = clock;
disp(['Runtime: ', num2str(etime(time_end,time_start))]);