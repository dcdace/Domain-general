% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12 and PLS functions

% OPTION INPUT
% Y             : Subject x Behavior Matrice
% analysis_name : string for analysis name (for saving data
% normmeth      : normalization method (1 = center; 2 = zscore, 3, 3 = center and normalize)
% X             : Subject x Voxel matrice encoding voxel activity
% figure_path   : path to save figures
% mask_file     : path of the binary mask image used as mask to extract X matrice
% z_cutoff      : treshold of Bootstrapped Standard Ratio to determine cluster (this is just to report results)
% Yname         : name of behaviral variable
% nperms        : number of permutation to test significance of LV
% nboot         : number of bootst to compute BSR of voxel
% aal_dir       : path of aal; Make sure AAL2.nii and aal2.xlsx are in the
% atlas directory (for cluster report) - see line 247

clearvars
close all

conPath     = '..\data\stats\MNI\model01';
scores      = '..\data\behavioural.mat';
maskFile    = '..\data\results\Univariate\meta_NTT_STG_conj.nii';
saveDir     = '..\data\PLS\';
plsDir      = '..\MATLAB\PLS';


subjID       = cellstr(spm_select('List', conPath, 'dir', '^s_'));

% excluding bivariate outlier
subjID(9) = [];

conID       = {'con_0012.nii'};
nSubjects   = size(subjID, 1);
nConds      = length(conID);

imgpath = {};

% determine volume dimensions
sfile   = fullfile(conPath, subjID{1}, conID{1});
V       = spm_vol(sfile);
[X,XYZ] = spm_read_vols(V);
dims    = size(X);

X_subj = nan([nSubjects dims]);

for subI = 1 : nSubjects    
       sfile    = fullfile(conPath, subjID{subI}, conID{1}); 
       V        = spm_vol(sfile);
       [X,XYZ]  = spm_read_vols(V);
       X_subj(subI,:,:,:) = X;
end

load(scores);

% excluding bivariate outlier
behavioural.Y(9,:) = [];

option.Y                = behavioural.Y;
option.analysis_name    = 'PLS_model01_excl549_5000_5000';
option.normmeth         = 3;

option.X = X_subj;

option.mask_file    = maskFile;
option.z_cutoff     = 1.96;
option.Yname        = behavioural.Yname;
option.nperms       = 5000;
option.nboot        = 5000;

option.aal_dir      = plsDir;
option.figure_path  = fullfile(saveDir, option.analysis_name);
if ~exist(option.figure_path, 'dir')
    mkdir(option.figure_path);
end

resultpls = PLS(option);
save(fullfile(option.figure_path, 'results.mat'), 'resultpls');



