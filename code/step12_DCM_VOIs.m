% % -------------------------------
% % Dace Apsvalka, @CBU 2017-2021
% % -------------------------------
% dependencies: SPM12

% parameters.rootPath  = '..\data';
% subjID               = cellstr(spm_select('List',parameters.rootPath,'dir','^s_'));
% parameters.model     = 'model01_concat';
% parameters.modelDir  = fullfile(parameters.rootPath, 'stats', 'native', parameters.model);
% parameters.ROIdir    = fullfile(parameters.rootPath, 'ROIs', 'DCM_VOIs_model01_concat');
% parameters.ROIname   = {'leftM1', 'rightVLPFC', 'rightDLPFC', 'rightHC'};

function parameters = step12_DCM_VOIs(subjID, parameters)
parameters.subjID = subjID;
destDir = fullfile(parameters.ROIdir, parameters.subjID);

if ~exist(destDir, 'dir')
    mkdir(destDir);
end
% locate SPM.mat file
parameters.fspm = fullfile(parameters.modelDir, parameters.subjID, 'SPM.mat');

nROIs = size(parameters.ROIname,2);

% Contrasts
%    1  'effects of interest;
%    2  'main effect of Inhibition';
%    3  'T  > NT';
%    4  'NT > T';
%    5  'Go > Stop';
%    6  'Stop > Go';
%    7  'Express';
%    8  'Inhibit';
%    9  'Express > Inhibit';
%    10 'Inhibit > Express'
%    11 'NT < Baseline'
%    12 'Stop < Baseline'
%    13 'Inhibit < Baseline'

% M1: Stop < Go & < baseline [5 and 12]
% HC: NT < T & < baseline [3 and 11]
% rDLPFC and rVLPFC: Stop > Go & NT > T [6 and 4]

for r = 1 : nROIs
    parameters.thresh        = 0.05;
    parameters.threshstep    = 0.01;
    % VOI will only be created if there are significant voxels, need to check this and lower the threshold if needed
    voiCreated               = 0; 
    parameters.thisRoi       = parameters.ROIname{r};
        
    parameters.contrast = 1;
    
    parameters.froi = spm_select('FPList', fullfile(parameters.ROIdir, parameters.thisRoi), ['^' parameters.subjID '.*\.nii$']);
    
    while ~voiCreated
        
        parameters.expression = createVOI(p);
        
        % check if the mat file was created
        voiMatFile = spm_select('FPList', fullfile(parameters.modelDir, parameters.subjID), ['^VOI_' parameters.thisRoi '.*\.mat$']);
        if exist(voiMatFile, 'file')
            voiCreated = 1;
        else
            parameters.thresh = parameters.thresh + parameters.threshstep;
        end
    end
    parameters.roi(r).thresh = parameters.thresh;
    voiFile       = cellstr(spm_select('FPList', fullfile(parameters.modelDir, parameters.subjID), ['^VOI_' parameters.thisRoi]));
    voiFileName   = cellstr(spm_select('List', fullfile(parameters.modelDir, parameters.subjID), ['^VOI_' parameters.thisRoi]));
    
    for i = 1 : size(voiFile,1)
        movefile(voiFile{i}, fullfile(destDir, voiFileName{i}));
    end
    % save roi voi parameters
    save(fullfile(destDir, ['parameters_' parameters.thisRoi '.mat']), 'p');
end

end

function expression = createVOI(parameters)
% createVOI(subjID, fspm, froi, roi, contrast, thresh)
maskRegion = fullfile(parameters.modelDir, parameters.subjID, 'mask.nii');
expression = 'i1';

% change the path to the current one in case files have moved
load(parameters.fspm)
SPM.swd = fullfile(parameters.modelDir, parameters.subjID);
save(parameters.fspm, 'SPM')
D = mardo(parameters.fspm);
D = cd_images(D, fullfile(parameters.rootPath, parameters.subjID));
save_spm(D);
%
matlabbatch{1}.spm.util.voi.spmmat                  = {parameters.fspm};
matlabbatch{1}.spm.util.voi.adjust                  = parameters.contrast(1); % F contrast
matlabbatch{1}.spm.util.voi.session                 = 1;
matlabbatch{1}.spm.util.voi.name                    = parameters.thisRoi;

matlabbatch{1}.spm.util.voi.roi{1}.mask.image       = {parameters.froi};

% add all other contrasts
if length(parameters.contrast) > 1
    for c = 2 : length(parameters.contrast)
        
        matlabbatch{1}.spm.util.voi.roi{c}.spm.spmmat       = {''}; % using SPM.mat above
        matlabbatch{1}.spm.util.voi.roi{c}.spm.contrast     = parameters.contrast(c);
        matlabbatch{1}.spm.util.voi.roi{c}.spm.threshdesc   = 'none';
        matlabbatch{1}.spm.util.voi.roi{c}.spm.thresh       = parameters.thresh;
        matlabbatch{1}.spm.util.voi.roi{c}.spm.extent       = 0;
        
        expression = [expression, ['&i' num2str(c)]];
    end
else
    expression = 'i1&i2';
    matlabbatch{1}.spm.util.voi.roi{2}.mask.image       = {maskRegion};
    matlabbatch{1}.spm.util.voi.roi{2}.mask.threshold   = 0.5;
end

matlabbatch{1}.spm.util.voi.expression = expression;

spm_jobman('run', matlabbatch);
end