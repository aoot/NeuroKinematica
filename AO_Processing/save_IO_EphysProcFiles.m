%% Function outline

% Goal: 
    % query by pt/study ID
    % extract fields of interest in mat file
    % restructure relevant data into matrix

%% Required resources

% Summary XLSX file 
    % trial IDs and mat filenames
% Directories for raw data locs
% Directories for saving post-processed data

%% pseudocode

% hardcode directories
IO_DataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';
RawDataDir = [IO_DataDir, filesep, 'Raw Electrophysiology MATLAB']; % filesep saves based OS syntax
ProcDataDir = [IO_DataDir, filesep, 'Processed Electrophysiology'];

% load XLSX file location
xlsxLoc = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';
cd(xlsxLoc)

% load summaryXLSX table (save in GitHub repo)
summaryXLSX = readtable("Subject_AO.xlsx");

% isolate a specific studyID
studyID = 1;

% query rows in summaryXLSX by specific pt hemisphere/studyID (single integer correlated with StudyNum)
filteredXLSX = summaryXLSX(summaryXLSX.StudyNum == studyID, :);

% identify rows with non-empty/non-NAN cells in the trialNum column 
trial_rows = ~isnan(filteredXLSX.trialNum); % logical operation
% trial_rows = ~cellfun(@isempty, filteredXLSX.trialNum) & ... ~cellfun(@(x) any(isnan(x)), filtered_table.trialNum);

% extract relevant .mat filenames in the ao_MAT_file column
mat_filelist = filteredXLSX.ao_MAT_file(trial_rows); % correspond with non-NAN/non-empty cells in the trialNum column
% output = cell array of relevant .mat filenames

% convert cell array to table
T_mat_filelist = cell2table(mat_filelist, 'VariableNames', {'MAT_filenames'});

% specify output filename
out_mat_filelist = fullfile(xlsxLoc, 'mat_filelist.xlsx');

% write table to an Excel file
writetable(T_mat_filelist, out_mat_filelist);

% combine RawDataDir with filename to creat load location
% load() % matfile

% loop through relevant mat files in cell array
for i = 1:height(mat_filelist)
    % use fuction(s) to isolate fields of interest 
        % look at code in GitHub repo: save_DLCprocFiles_er
        % 1. Find all spike files 'CSPK'
        % 2. Find all LFP 'CLFP'
        % 3. Find all mLFP 'CMacro_LFP'
        % 4. Find all TTL 'CDIG'
        % Optional Find EMG when used

    % create new struct containing fields of interest

    % save into one struct

    % save into new directory with new name

    % save(filename, new struct var) % filename ~ ProcDataDir combined with mat fileame
end 

%% functions

function mat_filelist = save_IO_mat_files(studyID)
    
    % load XLSX file location
    xlsxLoc = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';
    cd(xlsxLoc)

    % load summaryXLSX table (save in GitHub repo)
    summaryXLSX = readtable("Subject_AO.xlsx");

    % query rows in summaryXLSX by specific pt hemisphere/studyID (single integer correlated with StudyNum)
    filteredXLSX = summaryXLSX(summaryXLSX.StudyNum == studyID, :);

    % identify rows with non-empty/non-NAN cells in the trialNum column 
    trial_rows = ~isnan(filteredXLSX.trialNum); % logical operation

    % extract relevant .mat filenames in the ao_MAT_file column
    mat_filelist = filteredXLSX.ao_MAT_file(trial_rows); % correspond with non-NAN/non-empty cells in the trialNum column
    % output = cell array of relevant .mat filenames

    % convert cell array to table
    T_mat_filelist = cell2table(mat_filelist, 'VariableNames', {'MAT_filenames'});

    % specify output filename
    out_mat_filelist = fullfile(xlsxLoc, 'mat_filelist.xlsx');

    % write table to an Excel file
    writetable(T_mat_filelist, out_mat_filelist);

end
