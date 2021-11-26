% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12, MarsBar, RSA toolbox

clearvars; close all;

param.rootPath  = '..\data';
param.roiPath   = fullfile(param.rootPath, 'ROIs', 'native');
subjID          = cellstr(spm_select('List',param.rootPath,'dir','^s_'));
param.stats     = 'model01';

param.conditions  = {'NT','T','Stop','Go'};
param.ROI =  {'rightDLPFC', 'rightVLPFC', 'rightHC', 'leftM1'};

param.savePath = fullfile(param.rootPath, 'classification');

n = 1;
chance = 100/size(param.conditions,2);

strsize = size(param.ROI,1)*size(subjID,1);
results(strsize) = struct();

Opt.param.conditions = param.conditions;
for r = 1:size(param.ROI,1)
    for s = 1:size(subjID,1)
        disp([param.stats ' ' param.ROI{r} ' ' subjID{s}]);
        clear SPM
        
        statsDir    = fullfile(param.rootPath, 'stats', 'native', param.stats, subjID{s});
        spm_name    = fullfile(statsDir, 'SPM.mat');
        
        roiDir    = fullfile(param.roiPath, param.ROI{r}, param.ROI{r});
                        
        roi_Imgfile = spm_select('FPList', roiDir, ['^' subjID{s} '.*\.nii$']);
        roi_Matfile = spm_select('FPList', roiDir, ['^' subjID{s} '.*\.mat$']);
        if isempty(roi_Matfile)
            mars_img2rois(roi_Imgfile, roiDir, [subjID{s} '_' param.ROI{r}], 'i');
            roi_Matfile = spm_select('FPList', roiDir, ['^' subjID{s} '.*\.mat$']);
        end

        V           = spm_vol(roi_Imgfile);
        my_space    = mars_space(V);
        
        R           = maroi(roi_Matfile);
        [pts, ~]    = voxpts(R,my_space);
                        
        load(spm_name)       
        for i = 1 : size(SPM.xY.VY, 1)
            [PATHSTR,NAME,EXT] = fileparts(SPM.xY.VY(i).fname);
            strrep(PATHSTR, PATHSTR(1:end-4), [param.rootPath filesep subjID{s} filesep]);
            SPM.xY.VY(i).fname = fullfile(PATHSTR, [NAME EXT]);
            
        end
        Y       = spm_get_data(SPM.xY.VY, pts);
        [c,p]   = rsa_getSPMconditionVec(SPM,Opt.param.conditions);
        
        xX    = SPM.xX;                        %- Take the design
        KWY   = spm_filter(xX.K,xX.W*Y);       %- Filter the data
        beta  = xX.pKX*KWY;                    %- Parameter estimates
        res   = KWY - xX.xKXs.X*beta;          %- Residuals - seems to be faster than spm_sp('r',xX.xKXs,KWY);
        
        betaS  = beta(xX.iC,:);
        
        results(n).condition                = c;
        results(n).partition                = p;
        results(n).betaS                    = betaS;
        
        n = n + 1;
    end %subject
    fname = fullfile(param.savePath, ['betas_' param.stats '_' [param.conditions{:}] '_' param.ROI{r}]);
    save(fname, 'results', 'param');
end % roi


