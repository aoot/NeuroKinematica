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

    % plot raw and ecg-filtered time domain data for each row of current JSON file
    for BSTD_i = 1:size(BSTD_1_table, 1) % Loop through each row in current JSON

        %     % % Optional: plot unfiltered data
        %     % figure; % Create new figure for each plot
        %     % plot(temp_BSTD_table.TimeDomainData{BSTD_i}); % blue
        %     % title(sprintf('File %d, Row %d', json_i, BSTD_i));
        %
        % filter out ECG for each row of time domain data in current JSON
        tempData_1 = transpose(BSTD_1_table.TimeDomainData{BSTD_i}); % Transpose raw data for current row
        ecg = perceive_ecg(tempData_1, fs, plotit);

        %     % % Optional: plot ecg-filtered data
        %     % hold on;
        %     % plot(ecg.cleandata); % orange
        %     % title(sprintf('ECG Filtered Data: File %d, Row %d', json_i, BSTD_i));
        %     % hold off;

    end

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
BSLFP_times_1_table = cell2table(BSLFP_times_1.FullNAT);
disp(BSLFP_times_1(1,3)); % ensure correct file by start-time info


%% filter out ecg

plot(BSTD_1_table.TimeDomainData{1}); % plot raw time domain data for row 1

streamOfInt_transposed = transpose(BSTD_1_table.TimeDomainData{1}); % transpose raw data for row 1
ecg = perceive_ecg(streamOfInt_transposed,fs,plotit); % run perceive_ecg function

hold on
plot(ecg.cleandata) % plot ecg-filtered time domain data for row 1
hold off


%% Load Left & Right STN BrainSense LFP streaming sessions in OFF Med JSON Session Report

% BrainSense timedomain data table
streaming_TAB_1 = BSTD_1_table;

% Trim by STN of interest - LSTN, RSTN
stream_LEFT_1 = streaming_TAB_1(contains(streaming_TAB_1.Channel,'LEFT'),:); % L STN, R body
stream_RIGHT_1 = streaming_TAB_1(contains(streaming_TAB_1.Channel,'RIGHT'),:); % R STN, L body

% Determine duration (in seconds) of each stream
stream_LEFT_1_times = getDAYtimes(stream_LEFT_1.FirstPacketDateTime, stream_LEFT_1.TimeDomainData);
LEFT_sessDurations_seconds_1 = stream_LEFT_1_times.Duration;

stream_RIGHT_1_times = getDAYtimes(stream_RIGHT_1.FirstPacketDateTime, stream_RIGHT_1.TimeDomainData);
RIGHT_sessDurations_seconds_1 = stream_RIGHT_1_times.Duration;


%% 9/12/2023 BrainSense LFP streams (12) in JSON Session Report 1 - Off Med

% js1_Row	sessDur(s)	DLC_sessID	DLC_sessDur(s) 	Hemisphere	Notes: case videos (10) for JSON Session Report 1 - Off Med
% 1	        32	        NA	            NA	        L	        % • L_baseline, (Off Med, Off Stim @ 0 mA)
% 2	        32	        NA		        NA          R	        % • R_baseline, (Off Med, Off Stim @ 0 mA)
% 3	        47	        session001	    56	        L	        % • session001, set1 (Off Med, Off Stim @ 0 mA)
% 4	        41	        session002		40          R	        % • session002, set1 (Off Med, Off Stim @ 0 mA)
% 5	        38	        session003	    48	        L	        % • session003, set2 (Off Med, Off Stim @ 0 mA)
% 6	        34	        session004		44          R	        % • session004, set2 (Off Med, Off Stim @ 0 mA)
% 7	        322	        session005	    336	        L	        % • session005 (Off Med, Stim Ramping)
% 8	        251	        session006		262         R	        % • session006 (Off Med, Stim Ramping)
% 9	        36	        session007	    45	        L	        % • session007, set1 (Off Med, On Stim @ max mA)
% 10	    29	        session008		37          R	        % • session008, set1 (Off Med, On Stim @ max mA)
% 11	    28	        session009	    35	        L	        % • session009, set2 (Off Med, On Stim @ max mA)
% 12	    26	        session010		36          R       	% • session010, set2 (Off Med, On Stim @ max mA)


%% Isolate specific rows of interest in JSON Session Report 1 - Off Med

% Left STN, Right body
% Specific Rows of interest
L_rowfromTab_bsln = 1;
L_streamOfInt_bsln = stream_LEFT_1.TimeDomainData{L_rowfromTab_bsln}; % L_baseline (Off Med, Off Stim @ 0 mA)

L_rowfromTab_s1 = 3;
L_streamOfInt_s1 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s1}; % L_set1 (Off Med, Off Stim @ 0 mA)

L_rowfromTab_s3 = 5;
L_streamOfInt_s3 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s3}; % L_set2 (Off Med, Off Stim @ 0 mA)

L_rowfromTab_s5 = 7;
L_streamOfInt_s5 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s5}; % L_ramp (Off Med, Stim Ramping)

L_rowfromTab_s7 = 9;
L_streamOfInt_s7 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s7}; % L_set1 (Off Med, On Stim @ max mA)

L_rowfromTab_s9 = 11;
L_streamOfInt_s9 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s9}; % L_set2 (Off Med, On Stim @ max mA)


% Right STN, Left body
% Specific Rows of interest
R_rowfromTab_bsln = 2;
R_streamOfInt_bsln = stream_RIGHT_1.TimeDomainData{R_rowfromTab_bsln}; % R_baseline, (Off Med, Off Stim @ 0 mA)

R_rowfromTab_s2 = 4;
R_streamOfInt_s2 = stream_RIGHT_1.TimeDomainData{R_rowfromTab_s2}; % R_set1 (Off Med, Off Stim @ 0 mA)

R_rowfromTab_s4 = 6;
R_streamOfInt_s4 = stream_RIGHT_1.TimeDomainData{R_rowfromTab_s4}; % R_set2 (Off Med, Off Stim @ 0 mA)

R_rowfromTab_s6 = 8;
R_streamOfInt_s6 = stream_LEFT_1.TimeDomainData{R_rowfromTab_s6}; % R_ramp (Off Med, Stim Ramping)

R_rowfromTab_s8 = 10;
R_streamOfInt_s8 = stream_LEFT_1.TimeDomainData{R_rowfromTab_s8}; % R_set1 (Off Med, On Stim @ max mA)

R_rowfromTab_s10 = 12;
R_streamOfInt_s10 = stream_LEFT_1.TimeDomainData{R_rowfromTab_s10}; % R_set2 (Off Med, On Stim @ max mA)


%% Sanity Check Plotting

L_streamsofInt_OffMed = {L_streamOfInt_bsln, L_streamOfInt_s1, L_streamOfInt_s3, L_streamOfInt_s5, L_streamOfInt_s7, L_streamOfInt_s9}; % w/ baseline
% L_streamsofInt_OffMed = {L_streamOfInt_s1, L_streamOfInt_s3, L_streamOfInt_s5, L_streamOfInt_s7, L_streamOfInt_s9}; % w/o baseline

% non-ecg-filtered
% maybe hp filter

% Titles for each plot in L_streamsofInt_OffMed
plotTitles = {
    'LSTN baseline (Off Med, Off Stim @ 0 mA)',
    'LSTN set1 (Off Med, Off Stim @ 0 mA)',
    'LSTN set2 (Off Med, Off Stim @ 0 mA)',
    'LSTN ramp (Off Med, Stim Ramping)',
    'LSTN set1 (Off Med, On Stim @ max mA)',
    'LSTN set2 (Off Med, On Stim @ max mA)'};

figure
for L_i = 1:length(L_streamsofInt_OffMed)
    ts_LFP = 0:1/250:(height(L_streamsofInt_OffMed{L_i})-1)/250;

    subplot(6,1,L_i)
    plot(ts_LFP, L_streamsofInt_OffMed{L_i})
    title(plotTitles{L_i})
    xlabel('Time (s)')
    ylabel('LFP Amplitude (uV)')
    grid on
end



R_streamsofInt_OffMed = {R_streamOfInt_bsln, R_streamOfInt_s2, R_streamOfInt_s4, R_streamOfInt_s6, R_streamOfInt_s8, R_streamOfInt_s10}; % w/ baseline
% R_streamsofInt_OffMed = {R_streamOfInt_s2, R_streamOfInt_s4, R_streamOfInt_s6, R_streamOfInt_s8, R_streamOfInt_s10}; % w/o baseline

% Titles for each plot in L_streamsofInt_OffMed
plotTitles = {
    'RSTN baseline (Off Med, Off Stim @ 0 mA)',
    'RSTN set1 (Off Med, Off Stim @ 0 mA)',
    'RSTN set2 (Off Med, Off Stim @ 0 mA)',
    'RSTN ramp (Off Med, Stim Ramping)',
    'RSTN set1 (Off Med, On Stim @ max mA)',
    'RSTN set2 (Off Med, On Stim @ max mA)'};

figure
for R_i = 1:length(R_streamsofInt_OffMed)
    ts_LFP = 0:1/250:(height(R_streamsofInt_OffMed{R_i})-1)/250;

    subplot(6,1,R_i)
    plot(ts_LFP, R_streamsofInt_OffMed{R_i})
    title(plotTitles{R_i})
    xlabel('Time (s)')
    ylabel('LFP Amplitude (uV)')
    grid on
end


%% Load in Motor Trial Indices per video

% EUC indicies
eucINDICIES = readtable("EUC_Indicies.xlsx");

videoIDs = eucINDICIES.videoID;

% Need
% Tablet_StartFrame
% Tablet_StopFrame

% OFF Med
DLC_s1 = videoIDs(1:3); % set 1 [OFF Med, OFF Stim]
DLC_s3 = videoIDs(4:6); % set 2 [OFF Med, OFF Stim]
% DLC_5_ramp % OFF Med
DLC_s7 = videoIDs(7:9); % set 1 [OFF Med, ON Stim]
DLC_s9 = videoIDs(10:12); % set 2 [OFF Med, ON Stim]

% ON Med
DLC_13 = videoIDs(13:15); % set 1 [ON Med, OFF Stim]
DLC_15 = videoIDs(16:18); % set 2 [ON Med, OFF Stim]
% DLC_18_ramp % ON Med
DLC_20 = videoIDs(19:21); % set 1 [ON Med, ON Stim]
DLC_22 = videoIDs(22:24); % set 2 [ON Med, ON Stim]



%% Converted left and right cam case videos

vidLoc = [mainDir2, filesep , 'ConvertedVideos'];
cd(vidLoc)


%% Tablet video

% tab_vidObj = VideoReader('20230912_idea08_session001_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4');
% tab_vid = struct('cdata',zeros(tab_vidObj.Height,tab_vidObj.Width,3,'uint8'),'colormap',[]);

% Assuming 9_12_2023 LSTN, R body Tablet Frames were captured via Right Cam
TabletVideos = {'20230912_idea08_session001_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session003_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session005_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session007_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session009_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session013_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session015_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session018_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session020_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4',
    '20230912_idea08_session022_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4'};


% Initialize structure to hold all tab_vids
all_tab_vids = struct();
for tab_vid_i = 1:length(TabletVideos)
    tab_vidObj = VideoReader(TabletVideos{tab_vid_i});
    tab_vid = struct('cdata',zeros(tab_vidObj.Height,tab_vidObj.Width,3,'uint8'),'colormap',[]);

    % Convert Tablet Video to dataframe
    frami = 1;
    while hasFrame(tab_vidObj)
        tab_vid(frami).cdata = readFrame(tab_vidObj);
        frami = frami + 1;
    end
    whos tab_vid
    v1who = whos('tab_vid');
    round(v1who.bytes/1000000/1000,2)
    disp('Video1 done!')

    all_tab_vids.(sprintf('Video%d', tab_vid_i)) = tab_vid; % Save each tab_vid in initialized structure
end

save(fullfile(mainDir2, 'all_tab_vids.mat'), 'all_tab_vids'); % Save structure as a .mat file


%% Convert each tab_vid in all_tab_vids from a struct to a table

% Load all_tab_vids structure
load(fullfile(mainDir2, 'all_tab_vids.mat'), 'all_tab_vids');

all_tab_vids_table = struct();  % Initialize structure to hold tables
tab_vid_names = fieldnames(all_tab_vids);  % Get names of all tab_vids

for i = 1:length(tab_vid_names)
    tab_vid_name = tab_vid_names{i};
    tab_vid_struct = all_tab_vids.(tab_vid_name);
    all_tab_vids_table.(tab_vid_name) = struct2table(tab_vid_struct);
end

% Save the all_tab_vids_table to the workspace
save(fullfile(mainDir2, 'all_tab_vids_table.mat'), 'all_tab_vids_table');


%% Determine which frames to trim on based presence of tablet
% Loop through / Plot / Title with Frame #

% Use the first tab_vid_table for subsequent processes
first_tab_vid_table = all_tab_vids_table.(tab_vid_names{1});

% Example of using first_tab_vid_table
for fi = 1:height(first_tab_vid_table)
    imshow(first_tab_vid_table.cdata{fi})
    title(num2str(fi))
    pause
end

% open fig, press any key to advance frames
% ctrl c to close
% note start frame and stop frame per session

% Define:
% Tablet_StartFrame
% Tablet_StopFrame

% session001
% Tablet_StartFrame =  196;
% Tablet_StopFrame = 3060;


%% Load in experimental camera 2

% dlcVideos = {};

dlc_vidObj = VideoReader('20230912_idea08_session001_leftCam-0000-converted.mp4');
dlc_vid = struct('cdata',zeros(dlc_vidObj.Height,dlc_vidObj.Width,3,'uint8'),'colormap',[]);


%% Convert Experimental Video 2 to dataframe

frami = 1;
while hasFrame(dlc_vidObj)
    dlc_vid(frami).cdata = readFrame(dlc_vidObj);
    %    imshow(frame)
    frami = frami+1;
end
dlcTab_vid = struct2table(dlc_vid);
disp('Video1 done!')

% open fig, press any key to advance frames
% ctrl c to close
% note start frame and stop frame per session

% Refine:
% Tablet_StartFrame
% Tablet_StopFrame

% session001
s1_Tablet_StartFrame = 206;
s1_Tablet_StopFrame = 3060;


%% Trim DLC video by start and stop frame of Tablet video

dlcTab_vid2use = dlcTab_vid(s1_Tablet_StartFrame:s1_Tablet_StopFrame,:);


%% Load and Process CSV file

post_DLCproc_Dir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Clinical\post_DLCproc\09_12_2023_LSTN_v2';
cd(post_DLCproc_Dir)

csv_vidLoc  = [post_DLCproc_Dir , filesep , 'csv folder'];
save_matLoc = [post_DLCproc_Dir , filesep , 'mat folder'];
cd(csv_vidLoc)

addpath 'C:\Users\erinr\OneDrive\Documents\GitHub\NeuroKinematica\DLC_Processing'

dlcIO_processCSV('dirLOC',1,'userLOC',csv_vidLoc,'saveLOC',save_matLoc)



%% Isolate LFP and Video of iterest

cd(mainDir2)

% DLC session1, LFP stream 3

% L_streamOfInt_s1 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s1}; % L_set1 (Off Med, Off Stim @ 0 mA)
streamOfInt = L_streamOfInt_s1;

% Define Start and Stop Frames
DLC_s1_Move_StartFrame = table2array(eucINDICIES(1,"StartInd")); %%% Replace w/ Tablet STARTFrame
DLC_s1_Move_StopFrame = table2array(eucINDICIES(3, "StopInd")); %%% Replace w/ Tablet STARTFrame

% DLC_s1_Move_StartFrame = 774;
% DLC_s1_Move_StopFrame = 2780;


%% Load and Trim DLC Video MAT file

% Load MAT file corresponding to session
load('dlcDAT_20230912_session001_idea08_resnet50_rightCam-0000DLC.mat','outDATA')
d1_labDAT = outDATA;

% Trim MAT file
% dlc_lab2use = d1_labDAT(DLC_s1_Move_StartFrame:DLC_s1_Move_StopFrame,:);
dlc_lab2use = d1_labDAT(s1_Tablet_StartFrame:s1_Tablet_StopFrame,:);


% colNames = d1_labDAT.Properties.VariableNames;
% for dl = 1:width(dlc_lab2use)
%     hold on
%     plot(dlc_lab2use.(colNames{dl}))
%     hold off
% end


%% Sampling Rate Conversions and Calculations

totalNumSamples_Vid = height(dlc_lab2use);

totalNumSecs = totalNumSamples_Vid/60; % 60 fps

totalNumSamples_LFP = floor(totalNumSecs*250); % 250 samples per second


% Original signal (video) sampling rate at 60 Hz (fps)
ts_DLC = 0:1/60:(height(dlc_lab2use)-1)/60;

% Target signal (LFP) sampling rate at 250 Hz (samples per sec)
ts_LFP = 0:1/250:(height(streamOfInt)-1)/250;

% Interpolate - upsample kinematic data to match LFP sampling rate
allColNs = dlc_lab2use.Properties.VariableNames;
dlc_lab2use2int = table;
for coli = 1:width(dlc_lab2use)

    % Tmp col
    tmpCol = allColNs{coli};

    % % Interpolation
    % x_250 = interp1(ts_DLC, transpose(dlc_lab2use.(tmpCol)),...
    %     ts_LFP, 'spline');
    x_250 = interp1(ts_DLC, dlc_lab2use.(tmpCol), ts_LFP);

    dlc_lab2use2int.(tmpCol) = transpose(x_250);
end

%trimFrB_int = linspace(FRAMEstart,FRAMEend, length(ts_LFP));


%% spectrograms describing session recordings using Caleb's code

fs = 250;
nfft = 250;
window = 250;
overlap = 150;
lfpsamplerate = 2;
color = turbo(11);

addpath 'C:\Users\erinr\OneDrive\Documents\GitHub\NeuroKinematica\DLC_LFP\MDT-SampleCode'
UCH_PowerSnapTD_short(js_1)
UCH_PowerSnapLFPCL_short(js_1)


%% Kinematics and LFP plot
close all

tiledlayout(3,1,"TileSpacing","tight")
xTime = ts_LFP;
% plot(dlc_lab2use2int.fTip1_x)
% hold on
% yyaxis left

fTip1_X_smooth = smoothdata(dlc_lab2use2int.fTip1_x,'gaussian',70);
nexttile
plot(xTime,fTip1_X_smooth);
xlim([0 round(max(ts_LFP))])
xlabel('Time (s)')
ylabel('fTip1, X deflection')

ecg = perceive_ecg(transpose(streamOfInt),250,0);
% plot(ecg.cleandata);
% yyaxis right

nexttile
plot(xTime,ecg.cleandata);
xlim([0 round(max(ts_LFP))])
xlabel('Time (s)')
ylabel('LFP (uV)')


%% Filter LFP Timeseries Data

% L_streamOfInt_s1 = stream_LEFT_1.TimeDomainData{L_rowfromTab_s1}; % L_set1 (Off Med, Off Stim @ 0 mA)
% streamOfInt = L_streamOfInt_s1;

%[px,fx,tx] = pspectrum(streamOfInt, fs, 'spectrogram');
[pxx,fxx,txx] = pspectrum(ecg.cleandata, fs, 'spectrogram');
% outputs: power matrix, frequency vec, time vec

% Isolate power spectrum in the 13-35 Hz range
betaIdx = fxx >= 13 & fxx <= 35;
betaPower = pxx(betaIdx, :);
betaFrequency = fxx(betaIdx);
% outputs: power (betaPower) in beta frequency range (13-30 Hz) over time (t).


% Spectrogram - time-frequency-power plot
nexttile
surf(txx, betaFrequency, 10*log10(betaPower), 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlim([0 round(max(ts_LFP))])
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Beta Band Power');
colorbar;


%% compute LFP power / instantaneous LFP beta power and plot PSDs per session (using pspectrum function)

% bin data - bin size
% narrow, 2Hz windows


% Hilbert transform - obtain the amplitude envelope of LFP 
% study the instantaneous power of the LFP data
hilbertTransformed_LFP = hilbert(ecg.cleandata, fs);
amplitudeEnvelope = abs(hilbertTransformed_LFP);


% bandpass filter for beta
betaBand = [13 35]; % Beta frequency range
% bpFiltered_LFP = bandpass(streamOfInt, betaBand, fs);
bpFiltered_LFP = bandpass(ecg.cleandata, betaBand, fs);

% plot PSD to vizualize strength of the variations (energy) as a function of frequency
[pxx, fxx] = pspectrum(bpFiltered_LFP, fs);
plot(fxx, pxx);
xlabel('Frequency (Hz)');
ylabel('Power');
title('Power Spectral Density');


% Hilbert transform - obtain the amplitude envelope of LFP in the beta band.
% study the instantaneous power of the LFP data
hilbertTransformed_beta = hilbert(bpFiltered_LFP);
betaEnvelope = abs(hilbertTransformed_beta);


% plot Time-Frequency-Power relationship
figure;
tiledlayout(2,1,"TileSpacing","tight");

% Spectrogram
nexttile;
surf(txx, betaFrequency, 10*log10(betaPower), 'EdgeColor', 'none');
axis tight; view(0, 90);
xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('Beta Band Power');

% Amplitude Envelope
nexttile;
plot(ts_LFP, betaEnvelope);
xlabel('Time (s)'); ylabel('Amplitude');
title('Beta Band Amplitude Envelope');



%% LFP beta filtering + Hilbert Transform - obtain instantaneous phase and frequency of the LFP data

% initialize arrays to store max beta powers:
maxBetaPower_L = zeros(1, length(L_streamsofInt_OffMed));
maxBetaPower_R = zeros(1, length(R_streamsofInt_OffMed));

% 
for i = 1:length(L_streamsofInt_OffMed)
    lfpData = L_streamsofInt_OffMed{i};
    [inst_freq_filtered_L, maxBetaPower_L(i), ts_LFPtmp_L] = analyze_LFPBetaPower(lfpData, fs);
end

for i = 1:length(R_streamsofInt_OffMed)
    lfpData = R_streamsofInt_OffMed{i};
    [inst_freq_filtered_R, maxBetaPower_R(i), ts_LFPtmp_R] = analyze_LFPBetaPower(lfpData, fs);
end


% Store maxBetaPower (μV) results per condition in CSV File
conditions = {'baseline_OffOff', 'OffOff_s1', 'OffOff_s2', 'Off_ramp', 'OffOn_s1', 'OffOn_s2'};
T = table(conditions', maxBetaPower_L', maxBetaPower_R', 'VariableNames', {'Condition', 'maxBetaPower_L', 'maxBetaPower_R'});
writetable(T, 'maxBetaPower_per_Condition_OffMed.csv');



%% Check DLC labeled video

dlcLab_vidLoc = vidLoc;
cd(dlcLab_vidLoc)

dlc_lab_vidObj = VideoReader('20230912_idea08_session001_rightCam-0000DLC_resnet50_Clin_2023-09-12_LSTN_v3Oct3shuffle1_100000_labeled-converted.mp4');
dlc_lab_vid = struct('cdata',zeros(dlc_lab_vidObj.Height,dlc_lab_vidObj.Width,3,'uint8'),'colormap',[]);

frami = 1;
while hasFrame(dlc_lab_vidObj)
    dlc_lab_vid(frami).cdata = readFrame(dlc_lab_vidObj);
    %    imshow(frame)
    frami = frami+1;
end
dlcLabTab_vid = struct2table(dlc_lab_vid);
disp('Video1 done!')


dlc_lablab2use = dlcLabTab_vid(s1_Tablet_StartFrame:s1_Tablet_StopFrame,:);

%%
% sig analyzer app in sig proc tb

% how many samples = 4.1 samples in lfp

%% Animated plot

plotXaxis = xTime;
kinematicY = fTip1_X_smooth;
lfpY = ecg.cleandata;

% 4.1 samples per frame (60:250)
stePS = round(linspace(1,totalNumSamples_LFP,totalNumSamples_Vid)); % determine chunk of LFP

for fi = 1:height(dlc_lablab2use)

    subplot(4,1,1:2)
    imshow(dlc_lablab2use.cdata{fi}) % plot frame

    subplot(4,1,3)
    plot(plotXaxis(1:stePS(fi)),kinematicY(1:stePS(fi))) % plot upsamp lfp
    ylim([min(kinematicY) max(kinematicY)]) % % plot upsamp lfp
    xlim([0 max(plotXaxis)])

    subplot(4,1,4)
    plot(plotXaxis(1:stePS(fi)),lfpY(1:stePS(fi)))   % plot power  matrix, freq vec, time vec
    % 1:ste
    ylim([min(lfpY) max(lfpY)])
    xlim([0 max(plotXaxis)])

    if fi == 1
        pause
    end
    pause(0.01)

end

%% Incorporate Spectogram into Animated Kinematics-LFP Plot

% Define variables for animation
%totalNumSamples_LFP = length(ecg.cleandata);
%totalNumSamples_Vid = height(dlc_lablab2use);
%stePS = round(linspace(1, totalNumSamples_LFP, totalNumSamples_Vid));

disp(size(pxx)); % Should be [numFrequencies, numTimePoints]
disp(size(fxx)); % Should be [numFrequencies, 1]
disp(size(txx)); % Should be [numTimePoints, 1]


% Animation Loop
for fi = 1:height(dlc_lablab2use)

    % Display current video frame
    subplot(4,1,1:2)
    imshow(dlc_lablab2use.cdata{fi});

    % Plot kinematic data up to current frame
    subplot(4,1,3)
    plot(plotXaxis(1:stePS(fi)), kinematicY(1:stePS(fi)));
    ylim([min(kinematicY) max(kinematicY)]);
    xlim([0 max(plotXaxis)]);

    % Plot LFP data up to current frame
    subplot(4,1,4)
    plot(plotXaxis(1:stePS(fi)), lfpY(1:stePS(fi)));
    ylim([min(lfpY) max(lfpY)]);
    xlim([0 max(plotXaxis)]);

    % Find the index in the spectrogram that corresponds to the current frame
    currentSpectrogramIndex = find(txx >= plotXaxis(stePS(fi)), 1);
    if isempty(currentSpectrogramIndex)
        currentSpectrogramIndex = length(txx);
    end

    % Update and plot spectrogram up to current frame
    currentSpectrogram = pxx(:, 1:currentSpectrogramIndex);
    currentSpectrogramTime = txx(1:currentSpectrogramIndex);

    %subplot(4,1,5)
    % surf(currentSpectrogramTime, fxx, 10*log10(currentSpectrogram), 'EdgeColor', 'none');
    imagesc(currentSpectrogramTime, fxx, 10*log10(currentSpectrogram.'));
    axis xy;

    axis tight;
    view(0, 90);
    %xlim([0 plotXaxis(stePS(fi))]);
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title('Beta Band Power');
    colorbar;

    % Update the display
    drawnow;


end

%%


% %% Save animated plot as video
%
% animationDir = [mainDIR2 filesep 'animated_Vids'];
%
% % Create a video writer object
% v = VideoWriter(fullfile(animationDir, 'animatedPlot'));
%
% % Video duration in seconds
% totalNumSecs = totalNumSamplesVid/60; % 60 fps
%
% % Frame rate calculation
% animation_FrameRate = totalNumSamplesVid/totalNumSecs;
%
% % Set the frame rate for the video writer object
% v.FrameRate = animation_FrameRate;
%
% % Open video writer object
% open(v);
%
% % 4.1 samples per frame
% stePS = round(linspace(1,totalNumSamplesLFP,totalNumSamplesVid));
%
% for fi = 1:height(dlc_lablab2use)
%     % Create figure
%     f = figure('visible', 'off');
%
%     subplot(4,1,1:2)
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
%     pause(0.01)
%
%     % Capture the plot as an image
%     frame = getframe(f);
%     writeVideo(v, frame);
%     close(f);
%
% end
%
% % Close the video file
% close(v);
%
%
% %% Compress ASV output to MP4
%
% compressVideosJAT(animationDir)



%% compute LFP power / instantaneous LFP beta power and plot PSDs per session (using pspectrum function)

% pspectrum
% fxx - freq
% pxx - power

% [p, f, t] = pspectrum(streamOfInt, 'spectrogram');


% % bin data
% overlap
% spectrogram
% bp filter beta
% convert power
% hilbert transform
% time-frequency decomp.
% retain temporal resolution

%%

% positional data
% constext-dependent kinematic behav: resting, initiation, braking
% feature extraction and weighting via unsupervised ML 
% movement vigor - rest vs. move - freq. of movement

%% subfunctions


function [outTAB] = getDAYtimes(inputTIMES , inputSAMPLES)

dayTIMES = cell(height(inputTIMES),1);
dayS = cell(height(inputTIMES),1);
fullDtime = cell(height(inputTIMES),1);
durations = zeros(height(inputTIMES),1);
streamOffsets = nan(height(inputTIMES),1);
for ti = 1:height(inputTIMES)

    inputTi = inputTIMES{ti};

    % The input date-time string
    % dateTimeStr = '2023-09-08T17:47:31.000Z';

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
    durations(ti) = round(length(inputSAMPLES{ti})/250);

end


for di = 1:height(fullDtime)

    if di < height(fullDtime)
        t1 = fullDtime{di} + seconds(durations(di));
        t2 = fullDtime{di + 1};

        streamOffsets(di) = seconds(time(between(t1,t2)));

    end

end

dayT2 = cellfun(@(x) char(x), dayTIMES, 'UniformOutput',false);
dayS2 = cellfun(@(x) char(x), dayS, 'UniformOutput',false);
fDt = cellfun(@(x) char(x), fullDtime, 'UniformOutput',false);

outTAB = table(dayT2 , dayS2  , fDt , durations , streamOffsets,...
    'VariableNames',{'TimeOccur','DayOccur','FullNAT','Duration','Offset'});

% end

end



function [outTAB] = getBSLFPtimes(inputTIMES) % JAT helper function

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


function [inst_freq_filtered, maxBetaPower, ts_LFPtmp] = analyze_LFPBetaPower(lfpData, fs)

% Calculate time vector
ts_LFPtmp = (0:length(lfpData)-1) / fs;

% Apply Hilbert transform
hilbert_eeg = hilbert(lfpData);
inst_phase = angle(hilbert_eeg);
time = 1/fs;
inst_freq = diff(unwrap(inst_phase))/(2*pi*time);

% Filter instantaneous frequency for beta band (13-30 Hz)
bandpass_filt = designfilt('bandpassiir','FilterOrder',4, ...
    'HalfPowerFrequency1',13,'HalfPowerFrequency2',30, ...
    'SampleRate',fs);
inst_freq_filtered = filtfilt(bandpass_filt, inst_freq);
inst_freq_filtered(end+1) = 0;  % Padding the last value

% Calculate maximum beta power
maxBetaPower = max(abs(inst_freq_filtered));

% Plotting
plot(ts_LFPtmp, inst_freq_filtered);
xlim([0 round(max(ts_LFPtmp))]);
ylabel('Voltage (Beta Band)');
xlabel('Time (s)');
title(sprintf('Filtered LFP for Stream %d', i));

end

