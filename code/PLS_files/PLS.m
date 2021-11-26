function resultpls = PLS(option)
% -------------------------------
% Addapted from Gagnepain et al. (2017)
% https://doi.org/10.1523/JNEUROSCI.2732-16.2017 
% -------------------------------

% OPTION INPUT
% Y             : Subject x Behavior Matrice
% analysis_name : string for analysis name (for saving data)
% normmeth      : normalization method (1 = center; 2 = zscore, 3, 3 = center and normalize)
% X             : Subject x Voxel matrice encoding voxel activity
% figure_path   : path to save figures
% mask_file     : path of the binary mask image used as mask to extract X matrice
% z_cutoff      : treshold of Bootstrapped Standard Ratio to determine cluster (this is just to report results)
% Yname         : name of behaviral variable
% nperms        : number of permutation to test significance of LV
% nboot         : number of bootst to compute BSR of voxel
% aal_dir       : path of aal; Make sure AAL2.nii and aal2.xlsx are in the atlas directory (for cluster report) - see line 247

fnmask      = option.mask_file;
vol         = spm_vol(fnmask);
M_img       = [];
M_img       = spm_read_vols(vol);
IDX_Initial = find(M_img > 0);

% prepare data
X                   = option.X;
Y                   = option.Y;
nanid               = find(isnan(sum(X)));
X(:,nanid)      	= [];
%IDX_Initial(nanid)  = [];
% -------------------------------------------------------- mm
maskNanLOG=ismember(IDX_Initial,nanid);
IDX_Initial(maskNanLOG)=[];
% -------------------------------------------------------- mm

% run PLS correlation
% --------------------------------------------------------------------------

% save original data
x           = X;
y           = Y;

% normalize data
if option.normmeth == 1
    XDATA       = x - repmat(mean(x),size(x,1),1);
    YDATA       = y - repmat(mean(y),size(y,1),1);
elseif option.normmeth == 2
    XDATA       = zscore(x)./sqrt(size(x,1)-1);
    YDATA       = zscore(y)./sqrt(size(y,1)-1);
elseif option.normmeth == 3
    
    XDATA       = normalize(x - repmat(mean(x),size(x,1),1));
    YDATA       = normalize(y - repmat(mean(y),size(y,1),1));
    
    % !!! other normalization of brain activity (subject by subject) !!!!
        %     XDATA       = x - repmat(mean(x),size(x,1),1);
        %     XDATA       = normalize(XDATA')';
    % This normalization ensured that the voxels of each subject now have
    % the same variance and that differences between subjects are not due
    % to overall differences in activation (works better for me but
    % probably less usual, though see here (end of P.193): https://www.utdallas.edu/~herve/abdi-awbphkd-mubada2012.pdf

end

% get covariance matrice
R           = YDATA'*XDATA;

% run svd
[U,delta,V] = svdecon(R);

% scale salience (for plot ?)
Us      = U*delta;
Vs      = V*delta;


% get latent variable (scaled and unscaled)
LX          = XDATA*V;
LY          = YDATA*U;


deltaTrue = diag(delta);

% run permutation to identify significant dimension
% -------------------------------------------------

SVp = [];
for nB = 1:option.nperms
    
    % permute X
    rs = randperm(size(YDATA,1));
    Yr = YDATA(rs,:);
    rs = randperm(size(YDATA,1));
    Xr = XDATA(rs,:);
    
    % get permuted covariance matrice
    %         Rr = YDATA'*Xr;
    Rr = Yr'*Xr;
    
    % svd on permuted sample
    [Ur,delta_r,Vr] = svdecon(Rr);
    
    % rotate
    rotatemat       = rri_bootprocrust(V, Vr);
    Vrot            = Vr*delta_r*rotatemat;
    Urot            = Ur*delta_r*rotatemat;
    
    
    % store singular value
    SVp(nB,:) = sqrt(sum(Urot.^2));
    
end

SigDim = [];
for nD = 1:size(SVp,2)
    SigDim(nD) = length(find(SVp(:,nD) > deltaTrue(nD)))/size(SVp,1);
end


% plot correlation between LV and Y
% ---------------------------------

canvas  = [1 1 2048 1024] ;
f       = @(D) corr(D(:,1),D(:,2)); % function for bootci
col     = rand(length(SigDim),3);

for nD = 1:length(SigDim)
    
    fH      = figure;
    set(fH,'PaperPositionMode','auto','Position',canvas,'Color',[1 1 1]) ;
    hold on
    
    title(sprintf('Dimension %d',nD),'FontSize',18,'Fontweight','bold');
    for nY = 1:size(YDATA,2)
        D  = [LX(:,nD),YDATA(:,nY)];
        c  = corr(D(:,1),D(:,2));
        f  = @(D) corr(D(:,1),D(:,2));
        ci =  bootci(2000,{f, D},'type','per');
        
        h(nY) = bar(nY,c);
        e(nY) = errorbar(nY,c,ci(1)-c,ci(2)-c,'k');
        set(h(nY),'facecolor',col(nY,:),'LineWidth',3) ;
        set(e(nY),'LineWidth',2) ;
        
        if sum(ci>0) == 2 || sum(ci<0) == 2
            plot(nY,1.05,'p','MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0],'MarkerSize',20,'LineWidth',3);
        end
         resultpls.ci{nD,nY} = ci;
         resultpls.c{nD,nY} = c;
    end
    
    set(gca,'FontSize',15,'Ylim',[-1.2 1.2],'Xtick',[1:5],'Xticklabel',option.Yname);
    ylabel('Correlation')
    
    fn = fullfile(option.figure_path,[option.analysis_name,sprintf('_LVcorrDIM%d',nD)]);
    export_fig(fn,'-tiff');
    %close(fH)
    
   
%     
end


% run boostrap to identify significant voxel contributing to dimension
% --------------------------------------------------------------------------

Uboot = nan(option.nboot,size(U,1),size(U,2)); Vboot = nan(option.nboot,size(V,1),size(V,2));
for nB = 1:option.nboot
    
    % draw random sample with replacement
    rs = randsample(1:size(x,1),size(x,1),'true');
    
    % apply normization
    
    if option.normmeth == 1
        Xboot = x(rs,:) - repmat(mean(x(rs,:)),size(rs,2),1);
        Yboot = y(rs,:) - repmat(mean(y(rs,:)),size(rs,2),1);
        
    elseif option.normmeth == 2
        Xboot = zscore(x(rs,:));
        Yboot = zscore(y(rs,:));
        
    elseif option.normmeth == 3
        Xboot = normalize(x(rs,:) - repmat(mean(x(rs,:)),size(rs,2),1));
        Yboot = normalize(y(rs,:) - repmat(mean(y(rs,:)),size(rs,2),1));
    end
    
    % get cov matrice on bootstrap sample
    Rboot = Yboot'*Xboot;
    
    % run svd
    [Ub,delta_b,Vb] = svdecon(Rboot);
    
    % rotate axes
    rotatemat       = rri_bootprocrust(V, Vb);
    Vrot            = Vb*delta_b*rotatemat;
    Urot            = Ub*delta_b*rotatemat;
    Vrot            = normalize(Vrot);
    Urot            = normalize(Urot);
    
    % store
    for nD = 1:size(U,2)
        Uboot(nB,:,nD)     = Urot(:,nD);
        Vboot(nB,:,nD)     = Vrot(:,nD)';
    end
    
   
end

% compute boostrap ratio (voxel z-score for each dimension)
% --------------------------------------------------------------------------

% bootstrap ratio
Vz = [];
for nR  = 1:size(Vboot,2)
    for nD = 1:size(U,2)
        
        data        = squeeze(Vboot(:,nR,nD));
        sem         = std(data); % standard error of the mean
        Vz(nR,nD)   = (V(nR,nD))/sem;
    end
end



% create V zscore image for display of first dimension
% --------------------------------------------------------------------------

nD                  = 1; % dimension
Z                   = [];
Z                   = nan(vol.dim);
%Z(IDX_Initial)      = Vz(:,nD);
% -------------------------------------------------------- mm
nonnanid            = setdiff(1:numel(Z),nanid);
roiIs_LOG           = ismember(nonnanid,IDX_Initial);
Z(IDX_Initial)      = Vz(roiIs_LOG,nD);
% -------------------------------------------------------- mm

% write image
VO                      = {};
VO.fname                = fullfile(option.figure_path,[option.analysis_name,'_',sprintf('Dim%d_',nD),'zscore.nii']);
VO.dim                  = vol.dim;
VO.dt                   = vol.dt;
VO.dt(1)                = 16; % save with a format which accept NaN and Negative values .... !
VO.mat                  = vol.mat;

spm_write_vol(VO,Z)

% create cluster report
% --------------------------------------------------------------------------

dim             = vol.dim;
voxsize         = diag(vol.mat);
voxsize         = voxsize(1:3);
origin          = floor((vol.dim+1)/2); % not sure this is has a big impact, this is for cluster report, alternatively you can displau your mask image using spm display function and click on origin
K               = 10;
mindist         = 5;
z               = option.z_cutoff;
cluster_info    = plscmd_cluster_report(Z(IDX_Initial),z,-z,IDX_Initial',dim,voxsize',origin,1,K,mindist);
[jk cmax]       = max(abs(cluster_info.data{1}.peak_values));

OutputFileName      = fullfile(option.figure_path,[option.analysis_name,'_',sprintf('ClusterReport_Dim%d.txt',nD)]);
fid                 = fopen(OutputFileName,'w+t'); % open as writeable text
fprintf(fid,'Cluster\t X\t Y\t Z\t X(mm)\t Y(mm)\t Z(mm)\t BSR\t P(approx)\t Size(Vox)\t Label\t R-I\t R-VAL\n');

nClus           = length(cluster_info.data{1}.id);

atlas_resize    = fullfile(option.figure_path,'rAA2.nii');
aal_fn          = fullfile(option.aal_dir,'AAL2.nii');

if exist(atlas_resize) ~= 2
    matlabbatch{1}.spm.spatial.coreg.write.ref              = {fnmask};
    matlabbatch{1}.spm.spatial.coreg.write.source           = {aal_fn};
    matlabbatch{1}.spm.spatial.coreg.write.roptions.interp  = 1;
    matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap    = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.write.roptions.mask    = 0;
    matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix  = 'r';
    
    spm_jobman('run',matlabbatch);
    
    [Pa,Na,Ex]      = fileparts(aal_fn);
    new_fname      = [Pa,'/r',Na,Ex];
    
    movefile(new_fname,atlas_resize);
    
end
atlas       = spm_read_vols(spm_vol(atlas_resize));
%[atlas_code atlas_label] = xlsread(fullfile(option.aal_dir,'aal2.xls'));
[atlas_code atlas_label] = xlsread(fullfile(option.aal_dir,'aal2.xlsx'));

for cI = 1:nClus
    
    % cluster
    C1           = cI;
        
    % peak coord
    C2 = cluster_info.data{1}.peak_xyz(cI,1);
    C3 = cluster_info.data{1}.peak_xyz(cI,2);
    C4 = cluster_info.data{1}.peak_xyz(cI,3);
    
    % peak mm
    C5 = cluster_info.data{1}.peak_loc(cI,1);
    C6 = cluster_info.data{1}.peak_loc(cI,2);
    C7 = cluster_info.data{1}.peak_loc(cI,3);
    
    % BSR
    C8 = cluster_info.data{1}.peak_values(cI);
    
    % P (approx)
    C9 = normcdf(-abs(C8),0,1);
    
    % size
    C10 = cluster_info.data{1}.size(cI);
    
    % label
    code    = atlas(C2,C3,C4);
    lab     = atlas_label(find(atlas_code(:,3) == code));
    if isempty(lab)
        C11 = 'NaN';
    else
        C11     = lab{1};
    end
    
    % correlation
    D      = XDATA;
    clusid = cluster_info.data{1}.idx(find(cluster_info.data{1}.mask == cluster_info.data{1}.id(cI)));
    idD    = find(ismember(IDX_Initial,clusid));
    
    C      = corr(mean(D(:,idD),2),YDATA);
    
    C12    = C(1);
    if length(C)>1
    C13    = C(2);
    else
        C13 = NaN;
    end
%                 C14    = C(3);
    
    
    fprintf(fid,'%1.0f\t %1.0f\t %1.0f\t %1.0f\t %1.0f\t %1.0f\t %1.0f\t %2.2f\t %1.7f\t %1.0f\t %s\t %5.4f\t %5.4f\n',...
        C1,C2,C3,C4,C5,C6,C7,C8,C9,C10,C11,C12,C13);
    
end
%fclose('all')

% store some results
resultpls.U        = U;
resultpls.V        = V;
resultpls.percexp  = deltaTrue.^2./sum(deltaTrue.^2);
resultpls.sig      = SigDim;
resultpls.BSR      = Vz;
resultpls.LX       = LX;
resultpls.LY       = LY;
resultpls.options  = option;


% PLS BAYCREST

% datamat{1}                  = x;
% 
% option                      = [];
% option.method               = 3;
% option.num_perm             = 1000;
% option.num_split            = 0;
% option.num_boot             = 500;
% option.clim                 = 95;
% option.stacked_behavdata    = y;
% % option.stacked_designdata   = []'; use fore rotated PLS (5)
% option.meancentering_type   = 0;
% option.cormode              = 0;
% % option.boot_type            = 'strat';
% 
% 
% result = pls_analysis(datamat, 22, 1,option)




