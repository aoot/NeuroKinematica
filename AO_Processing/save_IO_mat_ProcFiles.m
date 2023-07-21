function mat_ProcFiles = save_IO_mat_ProcFiles(studyID, IO_DataDir, RawDataDir, ProcDataDir)

% isolate a specific subject
studyID = 1;
studyDataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_09_2023'; % directory where case-specific data in located

% hardcode directories
IO_DataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';  % directory where all IO data and list of .mat files is located
RawDataDir = [studyDataDir, filesep, 'Raw Electrophysiology MATLAB'];                    % directory where raw MATLAB data files are located (case-specific)                  
ProcDataDir = [studyDataDir, filesep, 'Processed Electrophysiology'];                    % directory where processed MATLAB data should be saved (case-specific)

% navigate to raw MAT file data
cd(RawDataDir)
IO_Matfile = dir('*.mat');           % get list of all .mat files in the current directory
IO_MatfileNames = {IO_Matfile.name}; % create cell array containing names of the .mat files found in previous step
% IO_MatfileName = IO_MatfileNames{1}; % sets fileName to be name of the first .mat file in the directory

% navigate to directory where list of .mat files is located
cd(IO_DataDir)
mat_filelist = readtable('mat_filelist.xlsx'); % loads .mat filenames from mat_filelist

% create struct containing only the .mat files in IO_Matfile (list of all .mat files in the studyID directory) that match the filenames in mat_filelist

% navigate to directory where raw MATLAB data files are located
cd(RawDataDir)

% initialize an empty struct to store matched files
MATmatchedFiles = struct;

% iterate over each file in mat_filelist
for i = 1:height(mat_filelist)

    % get current filename from the table
    currentFile = mat_filelist.MAT_filenames{i};

    % Check if the current file exists in IO_MatfileNames
    if ismember(currentFile, IO_MatfileNames)
        % If there is a match, load the mat file and save it in the struct
        % Replace '.' with '_' to create a valid field name
        fieldName = strrep(currentFile, '.', '_');
        MATmatchedFiles.(fieldName) = load(currentFile);
    end

end

    
for i = 1:height(mat_filelist)

    tmpFilename = MATmatchedFiles.FullFile{i}; % retrieve filename for i-th .mat file from the 'FullFile' field of mat_filelist
    matFileInfo = matfile(tmpFilename);     % create matfile object representing the .mat file specified by tmpFilename
    matFileVars1 = whos(matFileInfo);       % use 'whos' function to get info about variables stored in .mat file represented by matFileInfo 
    matFileVars2 = {matFileVars1.name};     % extract names of all variables in the .mat file and store them in cell array matFileVars2.
    
    % use fuction(s) to isolate fields of interest 
        % look at code in GitHub repo: save_DLCprocFiles_er
        
        % 2. Find all LFP 'CLFP'
        % 3. Find all mLFP 'CMacro_LFP'
        % 4. Find all TTL 'CDIG'
        % Optional Find EMG when used
        
    % 1. Find all spike files 'CSPK'
    [outStructSPK] = getFILEinfo('CSPK',matFileVars2,tmpFilename);
    % 2. Find all LFP
    [outStructLFP] = getFILEinfo('CLFP',matFileVars2,tmpFilename);
    % 3. Find all mLFP
    [outStructMLFP] = getFILEinfo('CMacro_LFP',matFileVars2,tmpFilename);
    % 4. Find all TTL
    [outStructTTL] = getFILEinfo('CDIG',matFileVars2,tmpFilename);
    % Optional Find EMG when used
    
    % create new struct containing fields of interest

    % save into one struct

    % save into new directory with new name

    % save(filename, new struct var) % filename ~ ProcDataDir combined with mat fileame

    % 1. Find all spike files
    % Save into one Struct
    dlcDepths.Spike = outStructSPK;
    dlcDepths.LFP = outStructLFP;
    dlcDepths.MLFP = outStructMLFP;
    dlcDepths.TTL = outStructTTL;

    % Save into new directory with new name
    sAVEname = ['DLCao_',tmpFilename];
    cd(dlcDATAdir)
    save(sAVEname,'dlcDepths');
end