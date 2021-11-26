% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12, need to be added to your MATLAB path

clearvars
rootPath = '..\data\';
statPath = fullfile(rootPath, 'stats','MNI','model01');
savePath = fullfile(rootPath, 'stats','group','model01');
maskImg  = '..\brainMask.nii';

if ~exist(savePath, 'dir')
    mkdir(savePath);
end

subjID = cellstr(spm_select('List',statPath,'dir','^s_'));

matlabbatch{1}.spm.stats.factorial_design.dir = {savePath};

for i = 1 : size(subjID, 1)
    
    matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i).scans = {
        fullfile(statPath, subjID{i}, 'con_0004.nii'); % Stop
        fullfile(statPath, subjID{i}, 'con_0003.nii'); % Go
        fullfile(statPath, subjID{i}, 'con_0002.nii'); % NT
        fullfile(statPath, subjID{i}, 'con_0001.nii')};% T
    
    matlabbatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i).conds = [
        1
        2
        3
        4];
end

matlabbatch{1}.spm.stats.factorial_design.des.anovaw.dept           = 1;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.variance       = 1;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.gmsca          = 0;
matlabbatch{1}.spm.stats.factorial_design.des.anovaw.ancova         = 0;
matlabbatch{1}.spm.stats.factorial_design.cov                       = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov                 = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none        = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im                = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em                = maskImg;
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit            = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no    = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm           = 1;


spm_jobman('run', matlabbatch);
save(fullfile(savePath, 'model.mat'), 'matlabbatch');
clear matlabbatch

%% ESTIMATE
matlabbatch{1}.spm.stats.fmri_est.spmmat            = {fullfile(savePath, 'SPM.mat')};
matlabbatch{1}.spm.stats.fmri_est.write_residuals   = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical  = 1;

spm_jobman('run', matlabbatch);
clear matlabbatch

%% CONTRASTS
% Stop Go NT T
matlabbatch{1}.spm.stats.con.spmmat                     = {fullfile(savePath, 'SPM.mat')};
matlabbatch{1}.spm.stats.con.consess{1}.fcon.name       = 'Unwhitened effects of interest';
matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights    = [
    0.75 -0.25 -0.25 -0.25
    -0.25 0.75 -0.25 -0.25
    -0.25 -0.25 0.75 -0.25
    -0.25 -0.25 -0.25 0.75];
matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep    = 'relp';

matlabbatch{1}.spm.stats.con.consess{2}.fcon.name       = 'main effect of Inhibition';
matlabbatch{1}.spm.stats.con.consess{2}.fcon.weights    = [1 -1 1 -1];
matlabbatch{1}.spm.stats.con.consess{2}.fcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{3}.fcon.name       = 'main effect of Modality';
matlabbatch{1}.spm.stats.con.consess{3}.fcon.weights    = [1 1 -1 -1];
matlabbatch{1}.spm.stats.con.consess{3}.fcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{4}.fcon.name       = 'Inhibition x Momain interaction';
matlabbatch{1}.spm.stats.con.consess{4}.fcon.weights    = [1 -1 -1 1];
matlabbatch{1}.spm.stats.con.consess{4}.fcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{5}.tcon.name       = 'Stop > Go';
matlabbatch{1}.spm.stats.con.consess{5}.tcon.weights    = [1 -1 0 0];
matlabbatch{1}.spm.stats.con.consess{5}.tcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{6}.tcon.name       = 'NT > T';
matlabbatch{1}.spm.stats.con.consess{6}.tcon.weights    = [0 0 1 -1];
matlabbatch{1}.spm.stats.con.consess{6}.tcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{7}.tcon.name       = 'Stop < Go';
matlabbatch{1}.spm.stats.con.consess{7}.tcon.weights    = [-1 1 0 0];
matlabbatch{1}.spm.stats.con.consess{7}.tcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{8}.tcon.name       = 'NT < T';
matlabbatch{1}.spm.stats.con.consess{8}.tcon.weights    = [0 0 -1 1];
matlabbatch{1}.spm.stats.con.consess{8}.tcon.sessrep    = 'repl';


matlabbatch{1}.spm.stats.con.consess{9}.tcon.name       = 'Stop > NT';
matlabbatch{1}.spm.stats.con.consess{9}.tcon.weights    = [1 0 -1 0];
matlabbatch{1}.spm.stats.con.consess{9}.tcon.sessrep    = 'repl';

matlabbatch{1}.spm.stats.con.consess{10}.tcon.name      = 'Stop < NT';
matlabbatch{1}.spm.stats.con.consess{10}.tcon.weights   = [-1 0 1 0];
matlabbatch{1}.spm.stats.con.consess{10}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{11}.tcon.name      = 'Go > T';
matlabbatch{1}.spm.stats.con.consess{11}.tcon.weights   = [0 1 0 -1];
matlabbatch{1}.spm.stats.con.consess{11}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{12}.tcon.name      = 'Go < T';
matlabbatch{1}.spm.stats.con.consess{12}.tcon.weights   = [0 -1 0 1];
matlabbatch{1}.spm.stats.con.consess{12}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{13}.tcon.name      = 'Interaction 1';
matlabbatch{1}.spm.stats.con.consess{13}.tcon.weights   = [-1 1 1 -1];
matlabbatch{1}.spm.stats.con.consess{13}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{14}.tcon.name      = 'Interaction 2';
matlabbatch{1}.spm.stats.con.consess{14}.tcon.weights   = [1 -1 -1 1];
matlabbatch{1}.spm.stats.con.consess{14}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{15}.tcon.name      = 'Inhibit';
matlabbatch{1}.spm.stats.con.consess{15}.tcon.weights   = [1 -1 1 -1];
matlabbatch{1}.spm.stats.con.consess{15}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{16}.tcon.name      = 'Express';
matlabbatch{1}.spm.stats.con.consess{16}.tcon.weights   = [-1 1 -1 1];
matlabbatch{1}.spm.stats.con.consess{16}.tcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.consess{17}.fcon.name      = 'interactionControl x Modality';
matlabbatch{1}.spm.stats.con.consess{17}.fcon.weights   = [-1 1 1 -1];
matlabbatch{1}.spm.stats.con.consess{17}.fcon.sessrep   = 'repl';

matlabbatch{1}.spm.stats.con.delete = 0;
spm_jobman('run', matlabbatch);
save(fullfile(savePath, 'contrasts.mat'), 'matlabbatch');
