% read in csv file
% loop through depths of interest per stn region

csvLoc = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';
cd(csvLoc) 

summaryCSV = readtable("Subject_AO.csv");

% Inputs: isolate a specific subject
studyID = 2;
studyDataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_23_2023\Raw Electrophysiology MATLAB'

% Completed subjects:
% 1: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_09_2023\Raw Electrophysiology MATLAB'
% 2: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_23_2023\Raw Electrophysiology MATLAB'

% Define data table and indexing variables:
studyTable = summaryCSV(ismember(summaryCSV.StudyNum,studyID),:);
studyTblIndex = ismember(summaryCSV.StudyNum,studyID); % logical index = loc of subject

% create and extract list of unique stn locations
stn_locs = unique(studyTable.stn_loc);

% loop through stn locations
for sti = 1:length(stn_locs)
    % create counter
    keepCount = 1;
    % hold current location
    temp_loc = stn_locs{sti};
    % find relevant rows of table
    stnlTable = studyTable(matches(studyTable.stn_loc,temp_loc),:);
    % stnlTblIndex = matches(summaryCSV.stn_loc,temp_loc); % logical index of stn depth
    % sumSTNIndex = studyTblIndex & stnlTblIndex; % links subject with stn depth
    % nameParts = cellfun(@(x) split(x,'.'),stnlTable.ao_MAT_file,'UniformOutput', false);
    % fileOrder = cellfun(@(x) str2double(x{2}(end)),nameParts, 'UniformOutput', true);

    % loop through files per stn location
    for stf = 1:height(stnlTable)
        temp_file = stnlTable.ao_MAT_file{stf};
        % find loc of temp file
        fileTblIndex = matches(summaryCSV.ao_MAT_file,temp_file); % notes row to save relvant experimental rec. ID 
        temp_dir = [studyDataDir,filesep,temp_file];
        % load(temp_dir)

        % do we care about this depth?
        matftemp = whos(matfile(temp_dir)); % look at filenames without loading file content
        matVarList = {matftemp.name}; % extract columns of cell array (filenames)
        ttlCHECK = matches('CDIG_IN_1_KHz',matVarList); % logical - if 1, we care ..maybe.
        
        % How many ttls?
        if ttlCHECK
            load(temp_dir,"CDIG_IN_1_Down")
            ttl_num =  length(CDIG_IN_1_Down) % 60 frames per sec.
            ttl_thresh = 60*30 % 30 sec
           if ttl_num < ttl_thresh
              summaryCSV.trialNum(fileTblIndex) = NaN;
           else
               % populate row with ID
               summaryCSV.trialNum(fileTblIndex) = keepCount;
               keepCount = keepCount +1;
           end
        else
           summaryCSV.trialNum(fileTblIndex) = NaN; % why is this condition here?
        end

    end
end

% save new CSV with trial ID
cd(csvLoc) % % cd to csvloc
writetable(summaryCSV,'Subject_AO.csv') % fill trial column

% output: csv file with column ID of trial (relevant experimental iteration)

stopTest = 1;
