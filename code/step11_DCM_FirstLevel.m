% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% % dependencies: SPM12, createNuisanceParameter_noConstant function
% 
% rootPath = '..\data';
% subjDir = cellstr(spm_select('FPList',rootPath,'dir','^s_'));
% subjID  = cellstr(spm_select('List',rootPath,'dir','^s_'));

function step11_DCM_FirstLevel(subjDir, subjID, rootPath)
nSess       = length(cellstr(spm_select('FPList', subjDir, 'dir', '^TNT')));
model       = 'model01_concat';
modelDir    = fullfile(rootPath, 'stats', 'native', model);
glmDir      = fullfile(modelDir, subjID);
if ~exist(glmDir,'dir')
    mkdir(glmDir);
end
%% DESIGN
matlabbatch{1}.spm.stats.fmri_spec.timing.units     = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT        = 2;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t    = 32;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0   = 16;
matlabbatch{1}.spm.stats.fmri_spec.fact             = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt             = 1;
matlabbatch{1}.spm.stats.fmri_spec.global           = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mask             = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi              = '';%'AR(1)';
matlabbatch{1}.spm.stats.fmri_spec.dir              = {glmDir};

% for each session
allscans = [];
for sess = 1 : nSess
    thisScans               = cellstr(spm_select('FPList',fullfile(subjDir, ['TNT' num2str(sess)]),'^ar.*\.img$'));
    nVolumesPerRun(sess)    = size(thisScans, 1);
    allscans                = [allscans; thisScans];
end

epiDirs                 = cellstr(spm_select('FPList', subjDir ,'dir', '^TNT'));
MotionParameterFilter   = 'rp_*.txt';
nuisancefileOutput      = createNuisanceParameter_noConstant(epiDirs, MotionParameterFilter, nVolumesPerRun);

matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans        = allscans;
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond         = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi        = {fullfile(subjDir, 'model01_concatinated_onsets_NoBorderOnstets24sTNT.mat')};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress      = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg    = {nuisancefileOutput};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf          = Inf;

%% SAVE AND RUN
timenow = fix(clock);
save(fullfile(glmDir, ['batch_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
spm_jobman('run', matlabbatch);
clear matlabbatch

%% CONCATINATE
spm_fmri_concatenate(fullfile(glmDir, 'SPM.mat'), nVolumesPerRun)

%% ESTIMATE

matlabbatch{1}.spm.stats.fmri_est.spmmat            = {fullfile(glmDir, 'SPM.mat')};
matlabbatch{1}.spm.stats.fmri_est.write_residuals   = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical  = 1;
spm_jobman('run', matlabbatch);
clear matlabbatch

% conditions: 'T','NT','Go','Stop','u (NT and Stop), 'Nuisance'
%% CONTRASTS
matlabbatch{1}.spm.stats.con.spmmat = {fullfile(glmDir, 'SPM.mat')};

contrast_names = {
    'T  > NT' ...
    'NT > T' ...
    'Go > Stop' ...
    'Stop > Go'...    
    'Express' ...
    'Inhibit' ...
    'Express > Inhibit' ...
    'Inhibit > Express' ...
    'NT < Baseline' ...
    'Stop < Baseline', ...
    'Inhibit < Baseline'
    };

contrasts = {
    % T     NT      Go     Stop    
    [1     -1       0      0      0] ... % T > NT
    [-1     1       0      0      0] ... % NT > T
    [0      0       1     -1      0] ... % Go > Stop
    [0      0      -1      1      0] ... % Stop > Go
    [0.5    0      0.5     0      0] ... % Express
    [0     0.5      0     0.5     0] ... % Inhibit
    [0.5   -0.5    0.5   -0.5     0] ... % Express > Inhibit
    [-0.5   0.5   -0.5    0.5     0] ... % Inhibit > Express
    [0      -1      0      0      0] ... % NT < Baseline
    [0      0       0     -1      0] ... % Stop < Baseline
    [0    -0.5      0    -0.5     0]     % Inhibit < Baseline
    };

% how many conditions of interest
cond_of_int = 4;

matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'effects of interest';
matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = eye(cond_of_int);
matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{2}.fcon.name = 'main effect of Inhibition';
matlabbatch{1}.spm.stats.con.consess{2}.fcon.weights = [1 -1 1 -1];
matlabbatch{1}.spm.stats.con.consess{2}.fcon.sessrep = 'repl';

for con = 1 : length(contrasts)        
    matlabbatch{1}.spm.stats.con.consess{con+2}.tcon.name = contrast_names{con};
    matlabbatch{1}.spm.stats.con.consess{con+2}.tcon.weights = contrasts{con};
    matlabbatch{1}.spm.stats.con.consess{con+2}.tcon.sessrep = 'none';
end

matlabbatch{1}.spm.stats.con.delete = 1;

%% SAVE AND RUN
timenow = fix(clock);
save(fullfile(glmDir, ['contrasts_batch_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
spm_jobman('run', matlabbatch);














