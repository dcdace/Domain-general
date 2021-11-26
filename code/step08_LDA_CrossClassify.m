% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12, RSA toolbox

clearvars; close all FORCE

% for randomisation
rng(sum(100*clock),'twister');

rootPath = fullfile('data', 'classification');

rois = {'rightDLPFC', 'rightVLPFC', 'rightHC', 'leftM1'};

maxperm = 2000;

f = waitbar(0,'1','Name','Classifying ...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(f,'canceling',0);

% load all beta files and get voxel sizes
for r = 1 : size(rois,2)
    betafile = spm_select('FPList', rootPath, ['^betas_model01_NTTStopGo_' rois{r} '.*\.mat$']);
    betas(r) = load(betafile);
    nS = size(betas(r).results,2);
    for i = 1 : nS
        nVox(i,r) = size(betas(r).results(i).betaS, 2);
    end
end
for r = 1 : size(rois,2)
    for i = 1 : nS
        % random subsample of x voxels
        nv = nVox(i,r); % totla  number
        %
        %         %% to keep voxel size equal across rois
        %         keepequal = 1;
        %         % nv = min(nVox(i,:));
        %         %if only 1 voxel, leave it, otherwise take a subset
        %         if min(nVox(i,:)) < 2
        %             nsubVox(i,r) = min(nVox(i,:));
        %         else
        %             nsubVox(i,r) = floor(min(nVox(i,:))*0.9);
        %         end
        %
        %% If don't need to keep rois equal size
        keepequal = 0;
        %if only 1 voxel, leave it, otherwise take a subset
        if nVox(i,r) < 2
            nsubVox(i,r) = nv;
        else
            nsubVox(i,r) = floor(nv*0.9);
        end
        
        % all possible combinations of voxel subsets but limited to maxperm
        
        % how many possible combinations are there
        x = nv - nsubVox(i,r) + 1;
        N = prod(x:nv)/factorial(nsubVox(i,r));
        
        if N < maxperm
            roi(r).subj(i).subsets = nchoosek(1:nv,nsubVox(i,r))';
        else
            for j = 1 : maxperm
                roi(r).subj(i).subsets(:,j) = randsample(nv, nsubVox(i,r));
            end
        end
        perm(i,r) = size(roi(r).subj(i).subsets, 2);
    end
end
totalPerm = sum(sum(perm));
thisPerm = 0;
for r = 1 : size(rois,2)
    for i = 1 : nS
        sumC = zeros(2,2);
        thisSumC = zeros(2,2);
        k = 0;
        
        if keepequal
            perm(i,r) = min(perm(i,:));
        end
        %
        for n = 1 : perm(i,r)
            thisPerm = thisPerm + 1;
            % Check for clicked Cancel button
            if getappdata(f,'canceling')
                break
            end
            % Update waitbar and message
            waitbar(thisPerm/totalPerm, f, sprintf('%.0f%%',thisPerm/totalPerm*100))
            
            randVoxels = roi(r).subj(i).subsets(:,n);
            
            indNT   = find(strcmp(betas(r).param.conditions, 'NT'));
            indT    = find(strcmp(betas(r).param.conditions, 'T'));
            indStop = find(strcmp(betas(r).param.conditions, 'CStop'));
            indGo   = find(strcmp(betas(r).param.conditions, 'Go'));
            
            % training data
            itrain = (betas(r).results(i).condition == indNT & betas(r).results(i).partition > 0)| (betas(r).results(i).condition == indT & betas(r).results(i).partition > 0);
            xtrain = zscore(betas(r).results(i).betaS(itrain,randVoxels))'; % )') = acccross voxels; ))' = across conditions
            ctrain = betas(r).results(i).condition(itrain)';
            ctrain(ctrain==3) = 1;
            ctrain(ctrain==4) = 2;
            ptrain = betas(r).results(i).partition(itrain)';
            
            % testing data
            itest = (betas(r).results(i).condition == indStop & betas(r).results(i).partition > 0)| (betas(r).results(i).condition == indGo & betas(r).results(i).partition > 0);
            xtest = zscore(betas(r).results(i).betaS(itest,randVoxels))'; % )') = acccross voxels; ))' = across conditions
            ctest = betas(r).results(i).condition(itest)';
            ctest(ctest==3) = 1;
            ctest(ctest==4) = 2;
            ptest = betas(r).results(i).partition(itest)';
            
            
            [cpred, ~] = classify_lda_Kclasses_pairs(xtrain,ctrain,xtest,ctest);
            thisC = confusionmat(ctest, cpred)/max(ptest);
            sumC = sumC+thisC;
            k = k  + 1;
            
%             %  opposite
%             [cpred, ~] = classify_lda_Kclasses_pairs(xtest,ctest,xtrain,ctrain);
%             thisC = confusionmat(ctrain, cpred)/max(ptrain);
%             sumC = sumC+thisC;
%             k = k  + 1;
            
        end
        confusionM(r).C(i,:) = reshape(sumC/sum(sumC(1,:)), 1, 4);
    end
    
end

delete(f)

res_stacked = [];
for i = 1 : size(rois,2)    
    res_stacked = [res_stacked; confusionM(i).C(:,1)];    
end
