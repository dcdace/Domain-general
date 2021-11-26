% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% % dependencies: SPM12, need to be added to your MATLAB path
% 
% rootPath = '..\data';
% subjDir      = (cellstr(spm_select('FPList',rootPath,'dir','^s_')));
% 
% parameters.sess_prfx    = 'TNT';
% parameters.T1location   = 'MPRAGE';
% parameters.templateFile = '../s_01/MPRAGE/Template_6.nii';

function step03_Normalisation(thisSubjDir, parameters)
n_sess = length(cellstr(spm_select('FPList', thisSubjDir, 'dir', '^TNT')));
datafiles_ar = [];
for sess = 1:n_sess
    thisSessFiles = cellstr(spm_select('FPList',fullfile(thisSubjDir,[parameters.sess_prfx num2str(sess)]),'^ar.*\.img$'));
    datafiles_ar = [datafiles_ar; thisSessFiles];
end
flowfieldName = cellstr(spm_select('FPList',fullfile(thisSubjDir,parameters.T1location),'^u_r'));

matlabbatch{1}.spm.tools.dartel.mni_norm.template               = {parameters.templateFile};
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj.flowfield    = flowfieldName;
matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj.images       = datafiles_ar;
matlabbatch{1}.spm.tools.dartel.mni_norm.vox                    = [3 3 3];
matlabbatch{1}.spm.tools.dartel.mni_norm.bb                     = [NaN NaN NaN
    NaN NaN NaN];
matlabbatch{1}.spm.tools.dartel.mni_norm.preserve               = 0;
matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm                   = [8 8 10];

spm_jobman('run', matlabbatch);
clear matlabbatch

