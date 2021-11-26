% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% % dependencies: SPM12

% rootPath = '..\data';
% 
% subjDir = cellstr(spm_select('FPList',rootPath,'dir','^s_'));
% 
% % == Main Directories
% parameters.dir_base        = rootPath;  % data directory
% parameters.dir_anatomical  = 'MPRAGE';  % directory including the T1 3D high resoluation anatomical data set
% parameters.sess_prfx       = 'TNT';     % EPI directory prefix
% 
% % == scanning parameters
% parameters.TR              = 2;     % repetition time in s
% parameters.num_slices      = 32;    % number of slices
% parameters.ref_slice       = 16;    % middle slice
% parameters.TA = parameters.TR-parameters.TR/parameters.num_slices; 
% parameters.slice_order     = 32:-1:1;


%% ========================================

function step01_PreProcessing(thisSubjDir, parameters)

timenow = fix(clock);

%% FILES
% selects all EPI images from all sessions
parameters.n_sess = length(cellstr(spm_select('FPList', thisSubjDir, 'dir', ['^' parameters.sess_prfx])));
for sess = 1:parameters.n_sess    
    datafiles{sess} = cellstr(spm_select('FPList',fullfile(thisSubjDir, [parameters.sess_prfx num2str(sess)]),'^fMR.*\.img$'));
end

%'mean*.nii' usually saved in the first session (run01) folder
mean_niifile    = cellstr(spm_select('FPList',fullfile(thisSubjDir, [parameters.sess_prfx num2str(1)]),'^mean.*\.img$'));
T1_file         = cellstr(spm_select('FPList',fullfile(thisSubjDir, parameters.dir_anatomical),'^sMR.*\.img$'));

%% REALIGNMENT

matlabbatch{1}.spm.spatial.realign.estwrite.data                = datafiles;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality    = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep        = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm       = 5;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm        = 1; % 0 - register to first; 1 - register to mean
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp     = 2;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap       = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight     = '';
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which      = [2 1]; % resliced images
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp     = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap       = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask       = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix     = 'r';

% save batch
save(fullfile(thisSubjDir, ['matlabbatch_Realignment_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
% run batch
spm_jobman('run', matlabbatch);
clear matlabbatch


%% SLICE TIMING CORRECTION

% use realigned files (prefix r) 
for sess    = 1:parameters.n_sess
    datafiles_r{sess} = cellstr(spm_select('FPList',fullfile(thisSubjDir, [parameters.sess_prfx num2str(sess)]),'^r.*\.img$'));
end

matlabbatch{1}.spm.temporal.st.scans    = datafiles_r;
matlabbatch{1}.spm.temporal.st.nslices  = parameters.num_slices;
matlabbatch{1}.spm.temporal.st.tr       = parameters.TR;
matlabbatch{1}.spm.temporal.st.ta       = parameters.TA;
matlabbatch{1}.spm.temporal.st.so       = parameters.slice_order;
matlabbatch{1}.spm.temporal.st.refslice = parameters.ref_slice;
matlabbatch{1}.spm.temporal.st.prefix   = 'a';

% save batch
save(fullfile(thisSubjDir, ['matlabbatch_SliceTimeCorr_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
% run batch
spm_jobman('run', matlabbatch);
clear matlabbatch

%% COREGISTRATION (anatomical to functional)
matlabbatch{1}.spm.spatial.coreg.estimate.ref               = mean_niifile;  
matlabbatch{1}.spm.spatial.coreg.estimate.source            = T1_file; 
matlabbatch{1}.spm.spatial.coreg.estimate.other             = {''}; 
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep      = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol      = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm     = [7 7];

% save batch
save(fullfile(thisSubjDir, ['matlabbatch_Coregistration_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
% run batch
spm_jobman('run', matlabbatch);
clear matlabbatch

%% SEGMENTATION
% segmentation, also generates Dartel import files
matlabbatch{1}.spm.spatial.preproc.channel.vols     = T1_file;
matlabbatch{1}.spm.spatial.preproc.channel.biasreg  = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write    = [0 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,1']};
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus  = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,2']};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus  = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,3']};
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus  = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,4']};
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus  = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,5']};
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus  = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm    = {[spm('Dir') filesep 'tpm/TPM.nii,6']};
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus  = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf         = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup     = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg         = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg      = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm        = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp        = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write       = [1 1];

% save batch
save(fullfile(thisSubjDir, ['matlabbatch_Segmentation_' date '_' num2str(timenow(4)) '_' num2str(timenow(5)) '.mat']), 'matlabbatch');
% run batch
spm_jobman('run', matlabbatch);
clear matlabbatch

