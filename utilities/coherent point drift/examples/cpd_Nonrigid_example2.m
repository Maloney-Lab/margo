%  Nonrigid Example 2. Coherent Point Drift (CPD).
%  Nonrigid registration of 2D fish point sets with noise and outliers.
%  Full set optioins is explicitelly defined. If you omit some options the
%  default values are used, see help cpd_register.
X = cenDat;
Y = centers;

% Init full set of options %%%%%%%%%%
opt.method='rigid'; % use nonrigid registration
opt.beta=2;            % the width of Gaussian kernel (smoothness)
opt.lambda=0.1;          % regularization weight

opt.viz=1;              % show every iteration
opt.outliers=0.7;       % use 0.7 noise weight
opt.fgt=0;              % do not use FGT (default)
opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
opt.corresp=0;          % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=2000;         % max number of iterations
opt.tol=1e-70;          % tolerance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[Transform, C]=cpd_register(X,Y, opt);

%figure,cpd_plot_iter(X, Y); title('Before');
%figure,cpd_plot_iter(X, Transform.Y, C);  title('After registering Y to X. And Correspondences');
