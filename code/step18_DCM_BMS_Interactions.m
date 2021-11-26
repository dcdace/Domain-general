% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12 

clearvars
parameters.rootPath = '..\data';
% 
parameters.model     = 'model01_concat';
parameters.version   = 'DCM_VOIs_model01_concat_maineffect05_73models';

parameters.modelDir  = fullfile(parameters.rootPath, 'DCM', parameters.model, parameters.version);
parameters.saveDir   = fullfile(parameters.modelDir, 'Interactions');

if ~exist(parameters.saveDir, 'dir')
    mkdir(parameters.saveDir);
end

subjID  = cellstr(spm_select('List',parameters.rootPath,'dir','^s_'));
matlabbatch{1}.spm.dcm.bms.inference.dir = {parameters.saveDir};

for s = 1 : size(subjID,1)
    models = cellstr(spm_select('FPList', fullfile(p.modelDir, subjID{s}), ['^DCM_' subjID{s} '.*e\.mat$']));
    models = models([9:12, 21:24]);      
    matlabbatch{1}.spm.dcm.bms.inference.sess_dcm{s}.dcmmat = models;
end
%
matlabbatch{1}.spm.dcm.bms.inference.model_sp                               = {''};
matlabbatch{1}.spm.dcm.bms.inference.load_f                                 = {''};
matlabbatch{1}.spm.dcm.bms.inference.method                                 = 'RFX';

matlabbatch{1}.spm.dcm.bms.inference.family_level.family(1).family_name     = 'None';
matlabbatch{1}.spm.dcm.bms.inference.family_level.family(1).family_models   = [1,5]';

matlabbatch{1}.spm.dcm.bms.inference.family_level.family(2).family_name     = 'D->V';
matlabbatch{1}.spm.dcm.bms.inference.family_level.family(2).family_models   = [2,6]';

matlabbatch{1}.spm.dcm.bms.inference.family_level.family(3).family_name     = 'D<-V';
matlabbatch{1}.spm.dcm.bms.inference.family_level.family(3).family_models   = [3,7]';

matlabbatch{1}.spm.dcm.bms.inference.family_level.family(4).family_name     = 'D<->V';
matlabbatch{1}.spm.dcm.bms.inference.family_level.family(4).family_models   = [4,8]';

matlabbatch{1}.spm.dcm.bms.inference.bma.bma_yes.bma_famwin = 'famwin'; % from the winning fmily

matlabbatch{1}.spm.dcm.bms.inference.verify_id                              = 1;

spm fmri;
spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);
