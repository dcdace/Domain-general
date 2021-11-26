% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% dependencies: SPM12

% parameters.rootPath  = '..\data';
% parameters.model     = 'model01_concat';
% parameters.version   = 'DCM_VOIs_model01_concat_maineffect05_73models';
% parameters.modelDir  = fullfile(parameters.rootPath, 'DCM', parameters.model, parameters.version);
% subjID      = cellstr(spm_select('List',parameters.rootPath,'dir','^s_'));
% 
% dcm_model = [];
% estimated = [];
% for s = 1:size(subjID,1)
%         dcm_model = [dcm_model; cellstr(spm_select('FPList', fullfile(parameters.modelDir, subjID{s}), ['^DCM_' subjID{s} '.*\.mat$']))];
%         estimated = [estimated; cellstr(spm_select('FPList', fullfile(parameters.modelDir, subjID{s}), ['^DCM_' subjID{s} '.*e\.mat$']))];
% end
% % exclude already estimated ones
% dcm_model = setdiff(dcm_model, estimated);

function step14_DCM_estimate_models(dcm_model)

spm_dcm_estimate(dcm_model);

% rename to know it has been estimated
[d, name, ext] = fileparts(dcm_model);
newname = [name 'e'];
movefile(dcm_model, fullfile(d, [newname ext]));


