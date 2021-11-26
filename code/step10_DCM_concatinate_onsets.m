% -------------------------------
% Dace Apsvalka, @CBU 2017-2021
% -------------------------------
% dependencies: SPM12, MarsBar, RSA toolbox

function step10_DCM_concatinate_onsets

parameters.rootPath = '\data';
subjID  = cellstr(spm_select('List',parameters.rootPath,'dir','^s_'));
parameters.conditions    = {'T','NT','Go','Stop','Nuisance'};
parameters.originalmodel = fullfile('stats', 'native', 'model01');

for i = 1 : size(subjID,1)
    disp(num2str(i));
    make_onset_files(subjID{i}, parameters);
end

function make_onset_files(subjID, parameters)

fspm = fullfile(parameters.rootPath, parameters.originalmodel, subjID, 'SPM.mat');
load(fspm)

nscans      = SPM.nscan;
TR          = SPM.xY.RT;

tmp.name    = parameters.conditions;
tmp.ons     = cell(1,size(parameters.conditions,2));
tmp.dur     = cell(1,size(parameters.conditions,2));

for cond = 1 : size(parameters.conditions,2)
    
    for sess = 1 : size(nscans,2)
        % check if this condition exists in this run        
        ind = find(strcmp([SPM.Sess(sess).U.name], parameters.conditions{cond}));
        
        if ~isempty(ind)    
            
            thisRunLenght               = nscans(sess) * TR;
            
            if sess == size(nscans, 2) % don't remove anything from the last run
                brd = 0; % 24 second cutoff
            else
                brd = 24; % 24 second cutoff
            end
            
            thisRunNoBorderOnsets       = SPM.Sess(sess).U(ind).ons(SPM.Sess(sess).U(ind).ons < (thisRunLenght - brd));
            thisRunBorderOnsets         = SPM.Sess(sess).U(ind).ons(SPM.Sess(sess).U(ind).ons > (thisRunLenght - brd));
            
            thisRunNoBorderDurations    = SPM.Sess(sess).U(ind).dur(SPM.Sess(sess).U(ind).ons < (thisRunLenght - brd));
            thisRunBorderDurations      = SPM.Sess(sess).U(ind).dur(SPM.Sess(sess).U(ind).ons > (thisRunLenght - brd));
            
            thisOns                     = thisRunNoBorderOnsets + sum(nscans(1:sess-1))* TR;
            tmp.ons{cond}               = [tmp.ons{cond};  thisOns];
            tmp.dur{cond}               = [tmp.dur{cond};  thisRunNoBorderDurations];
            
            % Border onsets added to Nuisance condition
            
            tmp.ons{5}               = [tmp.ons{5};  thisRunBorderOnsets + sum(nscans(1:sess-1))* TR;];
            tmp.dur{5}               = [tmp.dur{5};  thisRunBorderDurations];

        end
    end

end

%% make results for the existing conditions
k = 0;
for cond = 1 : size(parameters.conditions,2)    
    if ~isempty(tmp.ons{1,cond})
        k = k + 1;
        names{k}        = tmp.name{cond};
        onsets{k}       = tmp.ons{cond};
        durations{k}    = tmp.dur{cond};        
    end    
end

%% save
fsave = fullfile(parameters.rootPath, subjID, 'model01_concatinated_onsets_NoBorderOnstets24sTNT.mat');
save(fsave, 'names','onsets','durations','nscans','TR');
