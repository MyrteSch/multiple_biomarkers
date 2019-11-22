% Obtain information about the computation of the biomarker for 
% every situations or at least a pre-resection and post-resection
% situation
%
% cfg.bidsDir     - directory name of bids project
% cfg.resDir      - directory name of the result (biomarker computed 
%                   according to a specific format)
%
% analysis_info_T - table (subjName/all situations completed/any pre andany post)
function [ analysis_info_T ] = collect_info_about_situations_main(cfg)

bidsDir = cfg.bidsDir;
resDir  = cfg.resDir;

% obtain situation per subject from bids structure

subjList = dir(fullfile(bidsDir,'sub-RESP*'));
subjName = cell(numel(subjList),1);
sitXsubj = cell(numel(subjName),1);

for i = 1 : numel(subjList)
    
    strSub = regexpi(subjList(i).name,'(RESP\d*)','match'); 
    subjName{i} = strSub{1};
    
    sitList  = dir(fullfile(bidsDir,strcat('sub-',subjName{i}),'ses-SITUATION*'));
    c_sits   = [];
    for j = 1 : numel(sitList)
        aux       = regexp(sitList(j).name,'ses-(\w*)','tokens');
        c_sits{j} = aux{1}{1};
    end
    
    sitXsubj{i} = c_sits;
        
end

bids_map = containers.Map(subjName,sitXsubj,'UniformValues',false);

all_completed  = zeros(numel(subjName),1); 
anyPre_anyPost = zeros(numel(subjName),1);

% find subjects for which the biomarker was computed successfully
res_sit = cell(numel(subjName),1);

for i = 1 : numel(subjName)
    
    bids_sit  = bids_map(subjName{i});
    bids_Nsit = numel(bids_sit);
    
    res_sitList  = dir(fullfile(resDir,strcat('sub-',subjName{i},'*')));
    c_sits       = [];
    
    for j = 1 : numel(res_sitList)
        
        aux       = regexp(res_sitList(j).name,'\w*(SITUATION\w*)_','tokens');
        c_sits{j} = aux{1}{1};
    
    end
    res_sit    = c_sits;
    count      = zeros(size(res_sit));
    
    % for how many situaitons it was computed the biomarker successfully of the imported situations 
    for j = 1 : bids_Nsit
        
        count = count | strcmp(bids_sit{j},res_sit);
        
    end
    
    if(sum(count)== bids_Nsit)
        all_completed(i) = 1;
    end
    if(~isempty(res_sit)) 
        [bids_pre,bids_inter,bids_post] = find_pre_int_post(bids_sit);
        [res_pre,res_inter,res_post]    = find_pre_int_post(res_sit);

        if(any(bids_pre) && any(bids_post)) % at least one pre and one post situation is imported

            if(any(res_pre)) % at least one pre situation was computed

                anyP_P = 0;
                bids_post_sitName = bids_sit(bids_post);
                res_post_sitName  = res_sit(res_post);

                for k = 1 : numel(bids_post_sitName)
                    anyP_P = anyP_P | any(strcmp(bids_post_sitName{k},res_post_sitName));
                end
                anyPre_anyPost(i) = anyP_P;
            end

        end
    else % no biomarker computed for any of the imported situations (whole subject)
        anyPre_anyPost(i) = 0;
    end
     
end

analysis_info_T = table(all_completed,anyPre_anyPost,'RowNames',subjName);





