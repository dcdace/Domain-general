% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% dependencies: SPM12

function step13_DCM_specify_models
parameters.rootPath  = '..\data';

modelDir = fullfile(parameters.rootPath, 'DCM\model01_concat');

parameters.A = load(fullfile(modelDir, 'A.mat'));
parameters.B = load(fullfile(modelDir, 'B.mat'));
parameters.C = load(fullfile(modelDir, 'C.mat'));
parameters.isD = 0;
if exist(fullfile(modelDir, 'D.mat'), 'file')
    parameters.D = load(fullfile(modelDir, 'D.mat'));
    parameters.isD = 1;
end

parameters.model     = 'model01_concat';
parameters.statsPath = fullfile(parameters.rootPath, 'stats', 'native', parameters.model);
parameters.roiPath   = fullfile(parameters.rootPath, 'ROIs', 'DCM_VOIs_model01_concat');
parameters.version   = 'DCM_VOIs_model01_concat_maineffect05_73models';
parameters.rois      = {'rightM1', 'leftHC' ,'leftM1', 'rightHC'};
parameters.saveDir   = fullfile(modelDir, parameters.version);
parameters.cond      = {'NT', 'Stop', 'T', 'Go'};
parameters.TE        = 0.03;
parameters.ncond     = size(parameters.cond,2);
parameters.nrois     = size(parameters.rois,2);
parameters.center    = 1;

subjID = cellstr(spm_select('List',parameters.rootPath,'dir','^s_'));

for s = 1 : size(subjID,1)
    DCM_specify(subjID{s}, parameters);
end

%% ========================================

function DCM_specify(subjID, parameters)

saveDir = fullfile(parameters.saveDir, subjID);
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

disp(subjID)

%% ========================================================================
% SPECIFICATION

fGLM = fullfile(parameters.statsPath, subjID, 'SPM.mat');
load(fGLM);

% Load regions of interest
%--------------------------------------------------------------------------
for r = 1 : parameters.nrois
    froi = spm_select('FPList', fullfile(parameters.roiPath, subjID), ['^VOI_' parameters.rois{r} '.*_1\.mat$']);
    load(froi);
    DCM.xY(r) = xY;
end

DCM.n = length(DCM.xY);      % number of regions
DCM.v = length(DCM.xY(1).u); % number of time points

% Time series
%--------------------------------------------------------------------------
DCM.Y.dt  = SPM.xY.RT;
DCM.Y.X0  = DCM.xY(1).X0;
for i = 1:DCM.n
    DCM.Y.y(:,i)  = DCM.xY(i).u;
    DCM.Y.name{i} = DCM.xY(i).name;
end

DCM.Y.Q    = spm_Ce(ones(1,DCM.n)*DCM.v);

% Experimental inputs
%--------------------------------------------------------------------------
DCM.U.dt   =  SPM.Sess.U(1).dt;
DCM.U.name =  parameters.cond;

DCM.U.u = [];
for c = 1 : parameters.ncond
    DCM.U.u = [DCM.U.u SPM.Sess.U(strcmp([SPM.Sess.U.name], parameters.cond{c})).u(33:end,1)];
end

% DCM parameters and options
%--------------------------------------------------------------------------
DCM.delays = repmat(SPM.xY.RT/2,DCM.n,1);
DCM.TE     = parameters.TE;

DCM.options.two_state   = 0;
DCM.options.stochastic  = 0;
DCM.options.centre      = parameters.center;
DCM.options.induced     = 0;

% MODELS =================================================================
% a and c the same for all models
DCM.a = parameters.A.A;
DCM.c = parameters.C.C;
for i = 1:size(parameters.B.B, 2)
    DCM.b = parameters.B.B{i};
    if parameters.isD && any(parameters.D.D{i}(:))
        DCM.d = parameters.D.D{i};
        DCM.options.nonlinear = 1;
    else
        DCM.options.nonlinear = 0;
        DCM.d = double.empty(4,4,0);
    end
    m = ['m' num2str(i,'%02.f')];
    mfile = fullfile(saveDir, ['DCM_' subjID '_' m]);
    emfile = [mfile 'e.mat']; % estimated file name
    if ~exist(emfile, 'file')
        save(mfile, 'DCM');
    else
        disp(['already estimated: ' emfile])
    end
end

