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
    sessDate_field_2 = currentJSON.SessionDate;

    % Convert the string to a datetime object
    dateTimeObj_2 = datetime(sessDate_field_2, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z');

    % Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
    dateTimeObj_2.TimeZone = 'UTC';

    % Convert to Mountain Time
    dateTimeObj_Mountain_2 = datetime(dateTimeObj_2, 'TimeZone', 'America/Denver');

    % Extract the time component in AM/PM format
    timeComponent_AMPM = datetime(dateTimeObj_Mountain_2,'Format','hh:mm:ss a z');
    timeComponent_DATE = datetime(dateTimeObj_Mountain_2,'Format','dd-MMM-yyyy');

    % convert timedomain to table
    BSTD_2 = currentJSON.BrainSenseTimeDomain; % struct
    BSTD_2_table = struct2table(BSTD_2);

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
    [outTAB] = getBSLFPtimes(BSTD_2_table.FirstPacketDateTime);

    % Determine session start time - display first row of outTAB
    disp(outTAB(1,:));

    % Store the first row of outTAB in the session_StartTimes structure
    session_StartTimes.(sprintf('File%d', json_i)) = outTAB(1,:);

end

% JSON_name1 (...5956.json), FullNAT {'12-Sep-2023 10:17:12'},  Off Med
% JSON_name2 (...5939.json), FullNAT {'12-Sep-2023 11:31:25'},  On Med


%% Process On Med JSON Session Report 2nd

% % load JSON Session Report
% js_1_name = 'Report_Json_Session_Report_20230912T115956.json'
% js_1 = jsondecode(fileread(js_1_name));

js_2_name = 'Report_Json_Session_Report_20230912T115939.json';
js_2 = jsondecode(fileread(js_2_name));

% calculate the date/time
sessDate_field_2 = js_2.SessionDate;

% Convert the string to a datetime object
dateTimeObj_2 = datetime(sessDate_field_2, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z');

% Set the time zone to UTC (Coordinated Universal Time) since the input is in UTC
dateTimeObj_2.TimeZone = 'UTC';

% Convert to Mountain Time
dateTimeObj_Mountain_2 = datetime(dateTimeObj_2, 'TimeZone', 'America/Denver');

% convert BrainSense timedomain data to table
BSTD_2 = js_2.BrainSenseTimeDomain; % struct
BSTD_2_table = struct2table(BSTD_2); % table

% navigate to time domain data
BSLFP_times_2 = getBSLFPtimes(BSTD_2_table.FirstPacketDateTime);
BSLFP_times_2_table = cell2table(BSLFP_times_2.FullNAT);
disp(BSLFP_times_2(1,3)); % ensure correct file by start-time info

%% filter out ecg
plot(BSTD_2_table.TimeDomainData{1}); % plot raw time domain data for row 1

tempData_2 = transpose(BSTD_2_table.TimeDomainData{1}); % transpose raw data for row 1
ecg = perceive_ecg(tempData_2,fs,plotit); % run perceive_ecg function

hold on
plot(ecg.cleandata) % plot ecg-filtered time domain data for row 1
hold off


%% Load Left & Right STN BrainSense LFP streaming sessions in ON Med JSON Session Report

% BrainSense timedomain data table
streaming_TAB_2 = BSTD_2_table;

% Trim by STN of interest - LSTN, RSTN
stream_LEFT_2 = streaming_TAB_2(contains(streaming_TAB_2.Channel,'LEFT'),:); % L STN, R body
stream_RIGHT_2 = streaming_TAB_2(contains(streaming_TAB_2.Channel,'RIGHT'),:); % R STN, L body

% Determine duration (in seconds) of each stream
stream_LEFT_2_times = getDAYtimes(stream_LEFT_2.FirstPacketDateTime, stream_LEFT_2.TimeDomainData);
LEFT_sessDurations_seconds_2 = stream_LEFT_2_times.Duration;

stream_RIGHT_2_times = getDAYtimes(stream_RIGHT_2.FirstPacketDateTime, stream_RIGHT_2.TimeDomainData);
RIGHT_sessDurations_seconds_2 = stream_RIGHT_2_times.Duration;


%% 9/12/2023 BrainSense LFP streams (14) in JSON Session Report 2 - On Med						
							
% js2_Row	sessDur(s)	DLC_sessID	DLC_sessDur(s) 	Hemisphere	Notes
% 1	        32	        session011	    45	        L	        % • baseline_L, (On Med, Off Stim @ 0 mA)
% 2	        34	        session012	    42	        R	        % • baseline_R, (On Med, Off Stim @ 0 mA)
% 3	        38	        session013	    45	        L	        % • session013, set1 (On Med, Off Stim @ 0 mA) 
% 4	        29	        session014	    42	        R	        % • session014, set1 (On Med, Off Stim @ 0 mA) 
% 5	        32	        session015	    41	        L	        % • session015, set2 (On Med, Off Stim @ 0 mA)
    % 6                                                             % •  session016 interrupted by RC pt. compensation dropoff
% 7	        29	        session017	    37	        R	        % • session017, set2 (On Med, Off Stim @ 0 mA)
% 8	        153	        session018	    189	        L	        % • session018 (On Med, Stim Ramping) 
    % 9                                                             % • session019 (On Med, Stim Ramping) - LFP not captured
    % 10                                                            % •  scrap 
% 11	    28	        session020	    36	        L	        % • session020, set1 (On Med, On Stim @ max mA)
% 12	    26	        session021	    34	        R	        % • session021, set1 (On Med, On Stim @ max mA)
% 13	    26	        session022	    34	        L	        % • session022, set2 (On Med, On Stim @ max mA)
% 14	    25	        session023	    33	        R	        % • session023, set2 (On Med, On Stim @ max mA)


%% Isolate specific rows of interest in JSON Session Report 1 - On Med

% Left STN, Right body
% Specific Rows of interest
L_rowfromTab_js2_bsln = 1;
L_streamOfInt_js2_bsln = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_bsln}; % L_baseline (On Med, Off Stim @ 0 mA)

L_rowfromTab_js2_s1_OffStim = 3;
L_streamOfInt_js2_s1_OffStim = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_s1_OffStim}; % L_set1 (On Med, Off Stim @ 0 mA)

L_rowfromTab_js2_s2_OffStim = 5;
L_streamOfInt_js2_s2_OffStim = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_s2_OffStim}; % L_set2 (On Med, Off Stim @ 0 mA)

L_rowfromTab_js2_ramp = 8;
L_streamOfInt_js2_ramp = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_ramp}; % L_ramp (On Med, Stim Ramping) 

L_rowfromTab_js2_s1_OnStim = 11;
L_streamOfInt_js2_s1_OnStim = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_s1_OnStim}; % L_set1 (On Med, On Stim @ max mA)

L_rowfromTab_js2_s2_OnStim = 13;
L_streamOfInt_js2_s2_OnStim = stream_LEFT_2.TimeDomainData{L_rowfromTab_js2_s2_OnStim}; % L_set2 (On Med, On Stim @ max mA)


% Right STN, Left body
% Specific Rows of interest
R_rowfromTab_js2_bsln = 2;
R_streamOfInt_js2_bsln = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_bsln}; % R_baseline, (On Med, Off Stim @ 0 mA)

R_rowfromTab_js2_s1_OffStim = 4;
R_streamOfInt_js2_s1_OffStim = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_s1_OffStim}; % R_set1 (On Med, Off Stim @ 0 mA)

R_rowfromTab_js2_s2_OffStim = 7;
R_streamOfInt_js2_s2_OffStim = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_s2_OffStim}; % R_set2 (On Med, Off Stim @ 0 mA)

% R_rowfromTab_js2_ramp = 9;
% R_streamOfInt_js2_ramp = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_ramp}; % R_ramp (Off Med, Stim Ramping)

R_rowfromTab_js2_s1_OnStim = 12;
R_streamOfInt_js2_s1_OnStim = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_s1_OnStim}; % R_set1 (Off Med, On Stim @ max mA)

R_rowfromTab_js2_s2_OnStim = 14;
R_streamOfInt_js2_s2_OnStim = stream_RIGHT_2.TimeDomainData{R_rowfromTab_js2_s2_OnStim}; % R_set2 (Off Med, On Stim @ max mA)


%% Sanity Check Plotting

% L_streamsofInt_OffMed = {L_streamOfInt_js2_bsln, L_streamOfInt_js2_s1_OffStim, L_streamOfInt_js2_s2_OffStim, L_streamOfInt_js2_ramp, L_streamOfInt_js2_s1_OnStim, L_streamOfInt_js2_s2_OnStim}; % w/ baseline
% L_streamsofInt_OffMed = {L_streamOfInt_s1, L_streamOfInt_s3, L_streamOfInt_s5, L_streamOfInt_s7, L_streamOfInt_s9}; % w/o baseline
L_streamsofInt_OffMed = {L_streamOfInt_js2_bsln, L_streamOfInt_js2_s1_OffStim, L_streamOfInt_js2_s2_OffStim, L_streamOfInt_js2_s1_OnStim, L_streamOfInt_js2_s2_OnStim}; % w/o ramp

% Titles for each plot in L_streamsofInt_OffMed
% plotTitles = {
%     'LSTN baseline (Off Med, Off Stim @ 0 mA)', 
%     'LSTN set1 (Off Med, Off Stim @ 0 mA)', 
%     'LSTN set2 (Off Med, Off Stim @ 0 mA)', 
%     'LSTN ramp (Off Med, Stim Ramping)', 
%     'LSTN set1 (Off Med, On Stim @ max mA)', 
%     'LSTN set2 (Off Med, On Stim @ max mA)'};

plotTitles = {
    'LSTN baseline (Off Med, Off Stim @ 0 mA)', 

    'LSTN set1 (Off Med, Off Stim @ 0 mA)', 
    'LSTN set2 (Off Med, Off Stim @ 0 mA)', 
    
    'LSTN set1 (Off Med, On Stim @ max mA)', 
    'LSTN set2 (Off Med, On Stim @ max mA)'};

figure
for L_i = 1:length(L_streamsofInt_OffMed)
    % subplot(6,1,L_i)
    subplot(5,1,L_i)
    plot(L_streamsofInt_OffMed{L_i})
    title(plotTitles{L_i}) 
    xlabel('Time (s)') 
    ylabel('LFP Amplitude (uV)') 
    grid on 
end



% R_streamsofInt_OffMed = {R_streamOfInt_js2_bsln, R_streamOfInt_js2_s1_OffStim, R_streamOfInt_js2_s2_OffStim, R_streamOfInt_js2_ramp, R_streamOfInt_js2_s1_OnStim, R_streamOfInt_js2_s2_OnStim}; % w/ baseline
% R_streamsofInt_OffMed = {R_streamOfInt_s2, R_streamOfInt_s4, R_streamOfInt_s6, R_streamOfInt_s8, R_streamOfInt_s10}; % w/o baseline
R_streamsofInt_OffMed = {R_streamOfInt_js2_bsln, R_streamOfInt_js2_s1_OffStim, R_streamOfInt_js2_s2_OffStim, R_streamOfInt_js2_s1_OnStim, R_streamOfInt_js2_s2_OnStim}; % w/o ramp

% Titles for each plot in L_streamsofInt_OffMed
% plotTitles = {
%     'RSTN baseline (Off Med, Off Stim @ 0 mA)', 
%     'RSTN set1 (Off Med, Off Stim @ 0 mA)', 
%     'RSTN set2 (Off Med, Off Stim @ 0 mA)', 
%     'RSTN ramp (Off Med, Stim Ramping)', 
%     'RSTN set1 (Off Med, On Stim @ max mA)', 
%     'RSTN set2 (Off Med, On Stim @ max mA)'};

plotTitles = {
    'RSTN baseline (Off Med, Off Stim @ 0 mA)', 

    'RSTN set1 (Off Med, Off Stim @ 0 mA)', 
    'RSTN set2 (Off Med, Off Stim @ 0 mA)', 
    
    'RSTN set1 (Off Med, On Stim @ max mA)', 
    'RSTN set2 (Off Med, On Stim @ max mA)'};

figure
for R_i = 1:length(R_streamsofInt_OffMed)
    % subplot(6,1,L_i)
    subplot(5,1,R_i)
    plot(R_streamsofInt_OffMed{R_i})
    title(plotTitles{R_i}) 
    xlabel('Time (s)') 
    ylabel('LFP Amplitude (uV)') 
    grid on 
end


%% compute LFP power / instantaneous LFP beta power and plot PSDs per session (using pspectrum function)





%% spectrograms describing session recordings using Caleb's code

fs = 250;
nfft = 250;
window = 250;
overlap = 150;
lfpsamplerate = 2;
color = turbo(11);

% addpath 'C:\Users\erinr\OneDrive\Documents\GitHub\NeuroKinematica\DLC_LFP\MDT-SampleCode'
% UCH_PowerSnapTD_short(js_2)
% UCH_PowerSnapLFPCL_short(js_2)


%% Align LFP streams w/ movement / video data w/ rlevant marker (e.g., palm or finger tip)

% % Original signal at 60 Hz
% ts_DLC = 0:1/60:(height(dlc_lab2use)-1)/60;
% % Target sampling rate at 250 Hz
% ts_LFP = 0:1/250:(height(streamOfInt)-1)/250;


%% Kinematic and LFP plot




%% Animate 




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
