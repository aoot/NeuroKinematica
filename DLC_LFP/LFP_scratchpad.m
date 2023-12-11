%% Combine Percept LFP with DLC Video

% Data ingredients:
% 1) LFP - JSON Session Reports (1 report per hemisphere, multiple rows
% (recordings) per report [metadata informs ID of row])
% Preprocess subfunctions that determine relevant data, extracts, and stores it
% 2) Movement Indices

%% Directory set-up - Navigate b/t machines
pcname = getenv('COMPUTERNAME');

switch pcname
    case 'DESKTOP-I5CPDO7'   %%% JAT Desktop

        % mainDir = '';

    case 'DSKTP-JTLAB-EMR'   %%% ER Desktop

        mainDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Clinical\DLC_LFP';

    case 'NSG-M-FQBPFK3'     %%% ER PC

        mainDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Clinical\DLC_LFP';
end


%% Analyze data isolated by casedate and hemisphere

% Define casedate_hem
casedate_hem = '09_12_2023_LSTN';
% casedate_hem = '09_12_2023_RSTN';

mainDir2 = [mainDir , filesep , casedate_hem];

cd(mainDir2)

%% Navigate to LFP time domain data in JSON Session Reports

% Load JSON Session Reports
JSON_name1 = 'Report_Json_Session_Report_20230912T115956.json'; 
JSON_name2 = 'Report_Json_Session_Report_20230912T115939.json'; 
% JSON_name3 = ...
% etc.

% Create array of JSON Session Report file names
JSON_filenames = {JSON_name1, JSON_name2};

% Initialize structure to store the first row of outTAB for each JSON file
session_StartTimes = struct(); 

% Define perceive_ecg function params and add function paths
fs = 250;
plotit = 0; % 0 = don't plot, 1 = plot
addpath 'C:\Users\erinr\OneDrive\Documents\GitHub\NeuroKinematica\perceive-master'

% loop through each JSON file 
for json_i = 1:length(JSON_filenames)

    % load current JSON Session Report
    currentJSON_name = JSON_filenames{json_i}
    currentJSON = jsondecode(fileread(currentJSON_name));

    % calculate the date/time for the current JSON
    sessDate_field_1 = currentJSON.SessionDate;

    % Convert the string to a datetime object
    dateTimeObj_1 = datetime(sessDate_field_1, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z');

    % Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
    dateTimeObj_1.TimeZone = 'UTC';

    % Convert to Mountain Time
    dateTimeObj_Mountain_1 = datetime(dateTimeObj_1, 'TimeZone', 'America/Denver');

    % Extract the time component in AM/PM format
    timeComponent_AMPM = datetime(dateTimeObj_Mountain_1,'Format','hh:mm:ss a z');
    timeComponent_DATE = datetime(dateTimeObj_Mountain_1,'Format','dd-MMM-yyyy');

    % convert timedomain to table
    BSTD_1 = currentJSON.BrainSenseTimeDomain; % struct
    BSTD_1_table = struct2table(BSTD_1);

    % % plot raw and ecg-filtered time domain data for each row of current JSON file
    % for BSTD_i = 1:size(temp_BSTD_1_table, 1) % Loop through each row in current JSON 
    % 
    %     % % Optional: plot unfiltered data
    %     % figure; % Create new figure for each plot
    %     % plot(temp_BSTD_table.TimeDomainData{BSTD_i}); % blue
    %     % title(sprintf('File %d, Row %d', json_i, BSTD_i));
    % 
    %     % filter out ECG for each row of time domain data in current JSON
    %     tempData_1 = transpose(temp_BSTD_1_table.TimeDomainData{BSTD_i}); % Transpose raw data for current row
    %     ecg = perceive_ecg(tempData_1, fs, plotit);
    % 
    %     % % Optional: plot ecg-filtered data
    %     % hold on;
    %     % plot(ecg.cleandata); % orange
    %     % title(sprintf('ECG Filtered Data: File %d, Row %d', json_i, BSTD_i));
    %     % hold off;
    % end

    % navigate to time domain data
    [outTAB] = getBSLFPtimes(BSTD_1_table.FirstPacketDateTime);

    % Determine session start time - display first row of outTAB
    disp(outTAB(1,:));

    % Store the first row of outTAB in the session_StartTimes structure
    session_StartTimes.(sprintf('File%d', json_i)) = outTAB(1,:);

end

% JSON_name1 (...5956.json), FullNAT {'12-Sep-2023 10:17:12'},  Off Med
% JSON_name2 (...5939.json), FullNAT {'12-Sep-2023 11:31:25'},  On Med


%% Process OFF Med JSON Session Report 1st

% load JSON Session Report
js_1_name = 'Report_Json_Session_Report_20230912T115956.json'
js_1 = jsondecode(fileread(js_1_name));

% temp_JSON2_name = 'Report_Json_Session_Report_20230912T115939.json';
% temp_JSON2 = jsondecode(fileread(temp_JSON2_name));

% calculate the date/time
sessDate_field_1 = js_1.SessionDate;

% Convert the string to a datetime object
dateTimeObj_1 = datetime(sessDate_field_1, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z');

% Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
dateTimeObj_1.TimeZone = 'UTC';

% Convert to Mountain Time
dateTimeObj_Mountain_1 = datetime(dateTimeObj_1, 'TimeZone', 'America/Denver');

% convert BrainSense timedomain data to table
BSTD_1 = js_1.BrainSenseTimeDomain; % struct
BSTD_1_table = struct2table(BSTD_1); % table

% navigate to time domain data
BSLFP_times_1 = getBSLFPtimes(BSTD_1_table.FirstPacketDateTime);
disp(BSLFP_times_1(1,3)); % ensure correct file by start-time info


% %% filter out ecg
% plot(BSTD_1_table.TimeDomainData{1}); % plot raw time domain data for row 1
% 
% tempData_1 = transpose(BSTD_1_table.TimeDomainData{1}); % transpose raw data for row 1
% ecg = perceive_ecg(tempData_1,fs,plotit); % run perceive_ecg function
% 
% hold on
% plot(ecg.cleandata) % plot ecg-filtered time domain data for row 1 
% hold off


%% Load and find relevant streaming sessions from LFP in OFF Med JSON Session Report

% BrainSense timedomain data table
streaming_TAB_1 = BSTD_1_table; 

% Trim by STN of interest - LSTN, RSTN
stream_LEFT_1 = streaming_TAB_1(contains(streaming_TAB_1.Channel,'LEFT'),:); % L STN, R body
stream_RIGHT_1 = streaming_TAB_1(contains(streaming_TAB_1.Channel,'RIGHT'),:); % R STN, L body

L_sessTimes_1_cell = stream_LEFT_1.FirstPacketDateTime; % cell
L_sessTimes_1_table =  cell2table(L_sessTimes_1_cell); % table
L_sessTimes_1 = table2array(L_sessTimes_1_table); % array

% Initialize array to store trimmed session times (only min, sec, millisec)
trimmed_L_sessTimes_1 = strings(size(L_sessTimes_1));

% Loop through each time string
for L_time_i = 1:length(L_sessTimes_1)
    % Convert string to datetime
    dt = datetime(L_sessTimes_1(L_time_i), 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    
    % Format to keep only minute, second, and millisecond
    trimmed_L_sessTimes_1(L_time_i) = datestr(dt, 'MM:SS.FFF');
end

% Convert the trimmed times to duration
trimmed_L_sessDurs_1 = duration(trimmed_L_sessTimes_1, 'InputFormat', 'mm:ss.SSS');

% Find the offset from the first time
L_sessTimeOffsets_1 = trimmed_L_sessDurs_1 - trimmed_L_sessDurs_1(1);

% Initialize a base time
baseTime = duration(0, 0, 0);

% Apply the offset to the base time
L_uniformTimes_1 = baseTime + L_sessTimeOffsets_1;

% Calculate differences between consecutive times
L_sessDurations_1 = diff(L_uniformTimes_1);

% Convert the duration array to seconds
L_sessDurations_1_seconds = seconds(L_sessDurations_1);

   %  45 - r1
   % 122 - r2
   % 127 - r3               session001, set1 (Off Med, Off Stim @ 0 mA)          
   % 107 - r4
   %  75 - r5
   % 244 - r6
   % 482 - r7
   % 363 - r8
   %  76 - r9
   %  76 - r10
   %  68 - r11

%% 9/12/2023 case videos for JSON Session Report 1 - Off Med

% Left STN, R Body 
% •	session001, set1  	    (Off Med, Off Stim @ 0 mA)      54 sec
% •	session003, set2 		(Off Med, Off Stim @ 0 mA)      47 sec
% •	session005 		        (Off Med, Stim Ramping)         5 min, 35 sec (335 sec) - 6 streaming sessions     
% •	session007, set1  	    (Off Med, On Stim @ max mA)     44 sec     
% •	session009, set2 	    (Off Med, On Stim @ max mA)     34 sec

% Right STN, L Body 
% •	session002, set1		(Off Med, Off Stim @ 0 mA)
% •	session004, set2 		(Off Med, Off Stim @ 0 mA)
% •	session006 				(Off Med, Stim Ramping)
% •	session008, set1 		(Off Med, On Stim @ max mA)
% •	session010, set2 		(Off Med, On Stim @ max mA)


%% 9/12/2023 case videos for JSON Session Report 2 - On Med

% Left STN, R Body
% •	session013, session015 		(On Med, Off Stim @ 0 mA)
% •	session018 					(On Med, Stim Ramping)
% •	session020, session022		(On Med, On Stim @ max mA)

% Right STN, L Body
% •	session014, session017 		(On Med, Off Stim @ 0 mA)
% •	session019 					(On Med, Stim Ramping)
% •	session021, session023		(On Med, On Stim @ max mA)


%% Isolate specific rows of interest in JSON Session Report 1 - Off Med

% Left STN, Right body
% Specific Rows of interest
L_rowfromTab_1 = 3;
L_streamOfInt_1 = stream_LEFT_1.TimeDomainData{L_rowfromTab_1};


% Right STN, Left body
% Specific Rows of interest
% R_rowfromTab_1 = #;
% R_streamOfInt_1 = stream_RIGHT.TimeDomainData{R_rowfromTab_1};




%% Isolate dlc outputs of interest

% Generate list of dlc-video-labeled CSV files
mainCSV = dir('*.csv');
mainCSV2 = {mainCSV.name};

% Generate list of dlc-video-labeled MAT files
mainMat = dir('*.mat');
mainMAT2 = {mainMat.name};

% Generate list of Motor Index CSVs (filters for CSVs that contain 'Move' string)
moveCSV = mainCSV2(contains(mainCSV2,'Move'));


%% Main function

% create an outputs directory
outputDir = [mainDir2 filesep 'tempTests'];
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Loop through CSV files - Raw Data Processing
for csv_i = 1:length(moveCSV)

    tmpCSV = moveCSV{csv_i};

    % Split file names to extract relevant parts (dateID, sessID, and hemID)
    nameParts = split(tmpCSV,'_');
    dateID = nameParts{1};
    sessID = nameParts{3};
    hemID = nameParts{8};
    matName_title = [dateID , '-' , sessID, '-', hemID]

    % Find and load corresponding dlcDAT MAT file
    matTempfind = [dateID , '_' , sessID];
    matInd = contains(mainMAT2 , matTempfind);
    matName = mainMAT2{matInd};
    load(matName)

    % Process dlcDAT MAT file (all points, all frames) per vid first (Split column names of outDATA)
    colNames = outDATA.Properties.VariableNames; % outDATA should be a table containing labeled coordinate data from DeepLabCut
    colNames2 = cellfun(@(x) split(x,'_'), colNames,...
        'UniformOutput',false);
    colNames3 = unique(cellfun(@(x) x{1}, colNames2,...
        'UniformOutput',false));
    colNames4 = colNames3(~matches(colNames3,'frames'));

    % Initialize 'euclidall' to store Euclidean distances between successive points
    euclidall = zeros(height(outDATA)-1,length(colNames4));

    % Iterate over each label and compute Euclidean distance for each frame
    for label_i = 1:length(colNames4)

        tmpLabel_x = [colNames4{label_i} , '_x'];
        tmpLabel_y = [colNames4{label_i} , '_y'];

        tmpXdata = outDATA.(tmpLabel_x);
        tmpYdata = outDATA.(tmpLabel_y);

        labelData = [tmpXdata , tmpYdata];

        for frame_i = 1:height(labelData)
            if frame_i ~= height(labelData)
                point1 = labelData(frame_i,:);
                point2 = labelData(frame_i + 1,:);
                euclidall(frame_i , label_i) = pdist2(point1 , point2);
            end
        end
    end

    % Convert distance variables to mm usng conversion factor
    % euclidall = euclidall * pixels_to_mm; % converting euclidean distances to mm

    % Filter the computed distances related to fingertip movements
    fTipInds = contains(colNames4,'fTip');
    fTipEuclid = euclidall(:,fTipInds);

    % Average the computed distances related to fingertip movements
    fTipAverage = mean(fTipEuclid,2);

    % Process dlcDAT MAT files using MoveIndex CSV files to select specific portions of the averaged fingertip distances
    moveINDtab = readtable(tmpCSV);
    moveINDtab = moveINDtab(~moveINDtab.BeginF == 0,:); % clean up - filters out rows in moveINDtab where the BeginF field is zero.
    moveINDtab = moveINDtab(~moveINDtab.EndF == 0,:); % clean up - filters out rows in moveINDtab where the EndF field is zero.

    % Align with Euclidean distance frames
    firstBegin = moveINDtab.BeginF(1) - 1; % assigned to value of the first element in the BeginF column of moveINDtab - 1 (because MATLAB uses 1-based indexing)
    lastEnd = moveINDtab.EndF(height(moveINDtab)) - 1; % assigned to value of the last element in the EndF column of moveINDtab - 1

    % Extract and store the average fingertip distance for specified frames (in fTip Average Block)
    fTipAveBlk = fTipAverage(firstBegin:lastEnd); % extracts subset of fTipAverage w/in frame range from firstBegin to lastEnd (represents specific portion of data where specified movement is detected, as indicated in MoveIndex CSV file)

    % Smooth out edges -- smoothdata function w/ 'guassian' method
    window_Width = 5; % set windowWidth as needed
    smoothed_fTipAveBlk = smoothdata(fTipAveBlk, 'gaussian', window_Width); % read documentation, window overlap

end

cd(outputDir)








%%
% %% Load and Trim MAT file
% load('dlcDAT_20230912_session001_idea08_resnet50_rightCam-0000DLC.mat','outDATA')
% d1c_labDAT = outDATA.fTip1_x;
% 
% %%
% 
% dlc_lab2use = d1c_labDAT(206:3010,:);
% 
% % offsetSamples = 195;
% % offsetSecs = 195/60;
% totalNumSamplesV = height(dlc_lab2use);
% totalNumSecs = totalNumSamplesV/60; % 60 fps
% 
% totalNumSampsLFP = floor(totalNumSecs*250);





% %%
% % Original signal at 60 Hz
% ts_DLC = 0:1/60:(height(dlc_lab2use)-1)/60;
% % Target sampling rate at 250 Hz
% ts_LFP = 0:1/250:(height(streamOfInt)-1)/250;
% 
% allColNs = dlc_lab2use.Properties.VariableNames;
% dlc_lab2use2int = table;
% for coli = 1:width(dlc_lab2use)
% 
%     % Tmp col
%     tmpCol = allColNs{coli};
% 
%     % Interpolation
%     x_250 = interp1(ts_DLC, transpose(dlc_lab2use.(tmpCol)),...
%         ts_LFP, 'spline');
% 
%     dlc_lab2use2int.(tmpCol) = transpose(x_250);
% end

%
% %% Kinematic and LFP plot
% close all
%
% tiledlayout(2,1,"TileSpacing","tight")
% xTime = ts_LFP;
% % plot(dlc_lab2use2int.Elbow_x)
% % hold on
% % yyaxis left
% elbowXsm = smoothdata(dlc_lab2use2int.Elbow_x,'gaussian',70);
% nexttile
% plot(xTime,elbowXsm);
% xlim([0 round(max(ts_LFP))])
% ylabel('X deflection')
% xlabel('Time in seconds')
% ecg = perceive_ecg(transpose(streamOfInt),250,0);
% % plot(ecg.cleandata);
% % yyaxis right
% nexttile
% plot(xTime,ecg.cleandata);
% xlim([0 round(max(ts_LFP))])
% ylabel('uV')
% xlabel('Time in seconds')
%
%
%
% %%
% close all
% for di = 1:height(dlcTab_vid)
%     imshow(dlcTab_vid.cdata{di})
%     pause
%
% end
%
%
% %%
%
% for ffi = 1:height(dlcTab_vid2use.cdata)
%     imshow(dlcTab_vid2use.cdata{ffi})
%     hold on
%     plot(dlc_lab2use.PalmBase_x(ffi),dlc_lab2use.PalmBase_y(ffi),'ro')
%     pause(0.01)
%     cla
% end
%
% %% To do
%
% % 1. clean up interpolated point of interest
%
% % 2. clean up LFP with artifact removal
%
% % 3. instanteous theta , beta and gamma
%
%
% %% Check DLC labeled video
% dlcLab_vidLoc = mainDIR;
% cd(dlcLab_vidLoc)
%
% dlc_lab_vidObj = VideoReader('20230912_idea08_session001_leftCam-0000DLC_resnet50_Clin_2023-09-12_session1_labeled.mp4');
% dlc_lab_vid = struct('cdata',zeros(dlc_lab_vidObj.Height,dlc_lab_vidObj.Width,3,'uint8'),'colormap',[]);
%
% frami = 1;
% while hasFrame(dlc_lab_vidObj)
%     dlc_lab_vid(frami).cdata = readFrame(dlc_lab_vidObj);
%     %    imshow(frame)
%     frami = frami+1;
% end
% dlcLabTab_vid = struct2table(dlc_lab_vid);
% disp('Video1 done!')
%
%
% dlc_lablab2use = dlcLabTab_vid(206:3010,:);
%
%
% %% Animated plot
%
% plotXaxis = xTime;
% kinematicY = elbowXsm;
% lfpY = ecg.cleandata;
%
% % dlc_lablab2use
%
%
% % 4.1 samples per frame
% stePS = round(linspace(1,11688,2805));
%
% for fi = 1:height(dlc_lablab2use)
%     subplot(4,1,1:2)
%
%     imshow(dlc_lablab2use.cdata{fi})
%
%     subplot(4,1,3)
%     plot(plotXaxis(1:stePS(fi)),kinematicY(1:stePS(fi)))
%     ylim([min(kinematicY) max(kinematicY)])
%     xlim([0 max(plotXaxis)])
%
%     subplot(4,1,4)
%     plot(plotXaxis(1:stePS(fi)),lfpY(1:stePS(fi)))
%     ylim([min(lfpY) max(lfpY)])
%     xlim([0 max(plotXaxis)])
%
%     if fi == 1
%         pause
%     end
%
%     pause(0.01)
%
% end


%% subfunctions


% for ffi = 1:height(dlc_lablab2use.cdata)
%     imshow(dlc_lablab2use.cdata{ffi})
%     hold on
%     % plot(dlc_lab2use.PalmBase_x(ffi),dlc_lab2use.PalmBase_y(ffi),'ro')
%     pause(0.01)
%     cla
% end


% function [outTAB] = getDAYtimes(inputTIMES , inputSAMPLES) % JAT helper function - MDT2 INS 2024
%
% dayTIMES = cell(height(inputTIMES),1);
% dayS = cell(height(inputTIMES),1);
% fullDtime = cell(height(inputTIMES),1);
% durations = zeros(height(inputTIMES),1);
% streamOffsets = nan(height(inputTIMES),1);
%
% for ti = 1:height(inputTIMES)
%
%     inputTi = inputTIMES{ti};
%
%     % The input date-time string
%     % dateTimeStr = '2023-09-08T17:47:31.000Z';
%
%     % Convert the string to a datetime object
%     dateTimeObj = datetime(inputTi, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
%
%     % Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
%     dateTimeObj.TimeZone = 'UTC';
%
%     % Convert to Mountain Time
%     dateTimeObj_Mountain = datetime(dateTimeObj, 'TimeZone', 'America/Denver');
%
%     % Extract the time component in AM/PM format
%     timeComponent_AMPM = datetime(dateTimeObj_Mountain,'Format','hh:mm:ss a z');
%     timeComponent_DATE = datetime(dateTimeObj_Mountain,'Format','dd-MMM-yyyy');
%
%     % Display the time component
%     % disp(['Time in Mountain Time (AM/PM): ', timeComponent_AMPM]);
%     dayTIMES{ti} = timeComponent_AMPM;
%     dayS{ti} = timeComponent_DATE;
%     fullDtime{ti} = dateTimeObj_Mountain;
%     durations(ti) = round(length(inputSAMPLES{ti})/250);
%
% end
%
% end


function [outTAB] = getBSLFPtimes(inputTIMES) % JAT helper function - MDT2 INS 2024

dayTIMES = cell(height(inputTIMES),1);
dayS = cell(height(inputTIMES),1);
fullDtime = cell(height(inputTIMES),1);

for ti = 1:height(inputTIMES)

    inputTi = inputTIMES{ti};

    % Convert the string to a datetime object
    dateTimeObj = datetime(inputTi, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');

    % Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
    dateTimeObj.TimeZone = 'UTC';

    % Convert to Mountain Time
    dateTimeObj_Mountain = datetime(dateTimeObj, 'TimeZone', 'America/Denver');

    % Extract the time component in AM/PM format
    timeComponent_AMPM = datetime(dateTimeObj_Mountain,'Format','hh:mm:ss a z');
    timeComponent_DATE = datetime(dateTimeObj_Mountain,'Format','dd-MMM-yyyy');

    % Display the time component
    % disp(['Time in Mountain Time (AM/PM): ', timeComponent_AMPM]);
    dayTIMES{ti} = timeComponent_AMPM;
    dayS{ti} = timeComponent_DATE;
    fullDtime{ti} = dateTimeObj_Mountain;

end

dayT2 = cellfun(@(x) char(x), dayTIMES, 'UniformOutput',false);
dayS2 = cellfun(@(x) char(x), dayS, 'UniformOutput',false);
fDt = cellfun(@(x) char(x), fullDtime, 'UniformOutput',false);

outTAB = table(dayT2 , dayS2  , fDt,...
    'VariableNames',{'TimeOccur','DayOccur','FullNAT'});

end
