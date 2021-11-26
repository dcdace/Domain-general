% -------------------------------
% Addapted from Gagnepain et al. (2017)
% https://doi.org/10.1523/JNEUROSCI.2732-16.2017 
% -------------------------------

function nuisancefileOutput = createNuisanceParameter_noConstant(epiDirs,MotionParameterFilter,nVolumesPerRun, saveDir)

% epiDirs: structure with path of each session such as epiDirs{1} = 'path of session 1';

% MotionParameterFilter: wild card (e.g. 'rp*.txt') to identify motion parameter files in
% the session directory (used by the get_files function)

% nVolumesPerRun = vector of the nb of vol per session (e.g. [200, 250, ..., 220];

R        = [];
nS       = length(epiDirs);
nP       = 7; % nb of trends
nMP      = 6; % nb of Motion parameters
nVol     = sum(nVolumesPerRun);
% c        = nS; % nb of constant term
% 
% R = zeros(nVol,(nS*nP)+(nS*nMP)+c);
R = zeros(nVol,(nS*nP)+(nS*nMP));

col_idx =[]; col_idx = [1:nP:(nS*nP)+1];

row_idx = [];
for i = 1:(nS+1)
    
    if i == 1
        row_idx(i) = 1;
    elseif i > 1
        row_idx(i) = [sum(nVolumesPerRun(1:i-1))+1];
    end
    
end

% add trend parameters
for s = 1:nS
    trendX = [];
    trendX = generateTrendModel(nVolumesPerRun(s),3,1,0);
    R (row_idx(s):row_idx(s+1)-1,col_idx(s):col_idx(s+1)-1) = trendX;
end

% add motion paramater
col_idx = [col_idx(end):nMP:((nS*nP)+(nS*nMP))+1];
motion_files = get_files(epiDirs,MotionParameterFilter);

for s = 1:nS
    movementParams = [];
    movementParams = load(motion_files(s,:));
    R (row_idx(s):row_idx(s+1)-1,col_idx(s):col_idx(s+1)-1) = movementParams;
end

% % add constant term
% col_idx = col_idx(end):1:size(R,2);
% for s = 1:nS;
%     R (row_idx(s):row_idx(s+1)-1,col_idx(s)) = 1;
% end
% 
% R=R(:,1:end-1);
nuisancefileOutput = fullfile(epiDirs{1},'iRSAnuisanceparametersX.mat');
save(nuisancefileOutput,'R');

