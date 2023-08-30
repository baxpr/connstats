function connstats(varargin)

warning('off','MATLAB:table:RowsAddedExistingVars');

% Quit if requested (for extracting CTF in docker image)
if nargin>0 & strcmp(varargin{1},'quit')
    exit
end

% Inputs
P = inputParser;
addOptional(P,'matrix_csv','/INPUTS/R_removegm.csv')
addOptional(P,'remove_cerebellum','yes')
addOptional(P,'out_dir','/OUTPUTS')
parse(P,varargin{:});
disp(P.Results)
matrix_csv = P.Results.matrix_csv;
if ismember(P.Results.remove_cerebellum,{'1','yes','true'})
    remove_cerebellum = true;
else
    remove_cerebellum = false;
end
out_dir = P.Results.out_dir;


%% Read connectivity matrix from conncalc
%     https://github.com/baxpr/conncalc
C = readtable(matrix_csv,'ReadRowNames',true);

% We will exclude PostCereb_L and PostCereb_R from DMN before calculations
if remove_cerebellum
    disp('NOTE: Removing DMN PostCereb regions from calculation')
    keeps = ~contains(C.Properties.VariableNames,'DMN_PostCereb');
    C = C(keeps,keeps);
end

% And extract/parse ROI names. ROIs are named as r????_<network>_<region>
rois = table(C.Properties.VariableNames','VariableNames',{'roi'});
for h = 1:height(rois)
    q = strsplit(rois.roi{h},'_');
    rois.roinum{h,1} = q{1};
    rois.network{h,1} = q{2};
    rois.region{h,1} = strjoin(q(3:end),'_');
end


%% Individual edges
% Raichle2011 set has 36 ROIs, or 630 edges, so we won't extract edges for
% these ROIs
%result = table();
%for k1 = 1:size(C,1)-1
%    for k2 = k1+1:size(C,2)
%        rname = C.Row{k1}(7:end);
%        cname = C.Properties.VariableNames{k2}(7:end);
%        result.([rname '_' cname]) = C{k1,k2};
%    end
%end


%% Mean connectivity within and between Raichle 2011 networks
networks = unique(rois.network);
disp('Networks found:')
disp(networks)
result = table();
ct = 0;

% Within-network
for n1 = 1:numel(networks)
    for n2 = n1:numel(networks)
        
        % Limit to the networks of interest
        keeps1 = strcmp(rois.network,networks{n1});
        keeps2 = strcmp(rois.network,networks{n2});
        thisC = table2array(C(keeps1,keeps2));
        
        % If both networks the same, extract just the upper triangle so we
        % don't include the duplicate values or self-connections.
        if n1==n2
            inds = logical(triu(ones(size(thisC)),1));
            Clist = thisC(inds(:));
        else
            Clist = thisC(:);
        end
        
        ct = ct + 1;
        result.Network1{ct,1} = networks{n1};
        result.Network2{ct,1} = networks{n2};
        result.R_mean(ct,1) = mean(Clist);
    end
end


%% Save to file
writetable(result,fullfile(out_dir,'stats.csv'));


%% Exit
if isdeployed
    exit
end
