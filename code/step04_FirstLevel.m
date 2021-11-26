% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% % dependencies: SPM12
% 
% rootPath = '..\data';
% subjDir = cellstr(spm_select('FPList',rootPath,'dir','^s_'));
% subjID  = cellstr(spm_select('List',rootPath,'dir','^s_'));

function step04_FirstLevel(thisSubjDir, thisSubjID, rootPath)
nSess = length(cellstr(spm_select('FPList', thisSubjDir, 'dir', '^TNT')));
modelDir    = fullfile(rootPath, 'stats', 'MNI', 'model01');
glmDir      = fullfile(modelDir, thisSubjID);
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
matlabbatch{1}.spm.stats.fmri_spec.cvi              = 'AR(1)';
matlabbatch{1}.spm.stats.fmri_spec.dir              = {glmDir};

% for each session
for n = 1 : nSess
    movementFile = spm_select('FPList',fullfile(thisSubjDir, ['TNT' num2str(n)]),'^rp_fMR.*\.txt$');
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).scans        = (cellstr(spm_select('FPList',fullfile(thisSubjDir, ['TNT' num2str(n)]),'^swar.*\.img$')));
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).cond         = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).multi        = {spm_select('FPList',fullfile(thisSubjDir, ['TNT' num2str(n)]),'onsets\.mat$')};
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).regress      = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).multi_reg    = {movementFile};
    matlabbatch{1}.spm.stats.fmri_spec.sess(n).hpf          = 128;
    %end
end
   
%% ESTIMATE
matlabbatch{2}.spm.stats.fmri_est.spmmat            = {fullfile(glmDir, 'SPM.mat')};
matlabbatch{2}.spm.stats.fmri_est.write_residuals   = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical  = 1;

%% SAVE AND RUN   
timenow = fix(clock);
save(fullfile(glmDir, ['batch_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
spm_jobman('run', matlabbatch);   

clear matlabbatch

%% CONTRASTS
matlabbatch{1}.spm.stats.con.spmmat = {fullfile(glmDir, 'SPM.mat')};

%% create contrast weigts
conditions = {'T', 'NT', 'Go', 'Stop', 'Nuisance'};

rp_regressors = zeros(1,6);

contrast_names = {
    'T' ...
    'NT' ...
    'Go' ...
    'Stop' ...
    'Express' ...
    'Inhibit' ...
    'T  > NT' ...
    'NT > T' ...
    'Go > Stop' ...
    'Stop > Go'...
    'Express > Inhibit' ...
    'Inhibit > Express'
};

contrasts = {
   % T     NT      Go     Stop
    [1      0       0      0      0] ... % T
    [0      1       0      0      0] ... % NT
    [0      0       1      0      0] ... % Go
    [0      0       0      1      0] ... % Stop
    [0.5    0      0.5     0      0] ... % Express
    [0     0.5      0     0.5     0] ... % Inhibit    
    [1     -1       0      0      0] ... % T > NT
    [-1     1       0      0      0] ... % NT > T
    [0      0       1     -1      0] ... % Go > Stop
    [0      0      -1      1      0] ... % Stop > Go
    [0.5   -0.5    0.5   -0.5     0] ... % Express > Inhibit
    [-0.5   0.5   -0.5    0.5     0] ... % Inhibit > Express
    };

% load SPM
load(fullfile(glmDir, 'SPM.mat'));

nSess = length(SPM.Sess);

for con = 1 : length(contrasts)
    % current contrast
    
    new_contrast = [];
    con_used = nSess;
    
    for sess = 1 : nSess
        this_contrast = contrasts{con};
        % create contrasts for each session
        % session conditions
        this_conditions = [SPM.Sess(sess).U(:).name];
        
        % compare conditions with conSess to identify which conditions do
        % not exist
        condNotExist = ~ismember(conditions, this_conditions);
                
        % if any of the conditions that do not exist are in the contrast
        % then don't use this contrasts in this run (set all to 0)
        if any(this_contrast(condNotExist))
            this_contrast(1:end) = 0;
            con_used = con_used - 1;
        end
        
        % from the contrast, take out conditions that do not exist in this
        % session
        this_sess_contrast = this_contrast(~condNotExist);
        % add rp_regressors to the contrast
        new_contrast = [new_contrast this_sess_contrast rp_regressors];
        
    end
    % scaling the contrasts
    % divide the contrast by nRuns when the contrast is used
    new_contrast = new_contrast/con_used;
    
    %add to matlabbatch
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = contrast_names{con};
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = new_contrast;
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = 'none';
end

% how many conditions of interest (including null)
cond_of_int = 4;

matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.name = 'effects of interest';
matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.weights = eye(cond_of_int);
matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{con+2}.fcon.name = 'main effect of Inhibition';
matlabbatch{1}.spm.stats.con.consess{con+2}.fcon.weights = [1 -1 1 -1];
matlabbatch{1}.spm.stats.con.consess{con+2}.fcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.delete = 1;

%% SAVE AND RUN
timenow = fix(clock);
save(fullfile(glmDir, ['contrasts_batch_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
spm_jobman('run', matlabbatch);



