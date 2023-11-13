%% fTip tracking script (v5)

% Goal: analyze fingertip movement timeseries data based on videos that have been anatomically labeled (13pt per frame) and analyzed via a trained DeepLabCut model

%% Directory set-up - Navigate b/t machines
pcname = getenv('COMPUTERNAME');

switch pcname
    case 'DESKTOP-I5CPDO7'   %%% JAT Desktop

        % mainDir = '';

    case 'DSKTP-JTLAB-EMR'   %%% ER Desktop

        mainDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Clinical\Kinematic Analyses';
    case 'NSG-M-FQBPFK3'     %%% ER PC

        mainDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Clinical\Kinematic Analyses';
end


%% Analyze data isolated by casedate and hemisphere

% Define switch case inputs
casedate = '09_12_2023';
hemisphere = 'L';

switch casedate
    case '09_12_2023'

        mainDir2 = [mainDir , filesep , '09_12_2023'];

    case '[insert relevant casedate]'

        mainDir2 = [mainDir , filesep , 'relevant casedate'];
end


switch hemisphere
    case 'L'

        mainDir3 = [mainDir2 , filesep , 'LSTN'];

    case 'R'

        mainDir3 = [mainDir2 , filesep , 'RSTN'];
end

cd(mainDir3)


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
outputDir = [mainDir3 filesep 'fTipTracking_outputs_mm'];
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Define framerate of videos (time conversion factor)
fps = 60; % frames per second

% Convert distance units to mm (distance conversion factor)
pixels_to_mm = 2.109; % 232 mm / 110 pxl = 2.1091 mm per pixel
% Anthropometry: vertical distance from the bottom of the chin (menton) to the top of the head: https://upload.wikimedia.org/wikipedia/commons/0/06/AvgHeadSizes.png
% US adult male, 50th percentile: Avg. = 23.2 cm, 9.1 inches
% Subject in video frames: Avg. = 110 pixels

% set up a results structure outside of loop
results = struct();

% initialize variables to store the mean and variability for each video:
mean_amplitudes = zeros(1, length(moveCSV));
std_amplitudes = zeros(1, length(moveCSV));
var_amplitudes = zeros(1, length(moveCSV));

mean_widths = zeros(1, length(moveCSV));
std_widths = zeros(1, length(moveCSV));
var_widths = zeros(1, length(moveCSV));

mean_peakDists = zeros(1, length(moveCSV));
std_peakDists = zeros(1, length(moveCSV));
var_peakDists = zeros(1, length(moveCSV));

% initialize arrays to store concatenated data for selected videos/conditions:
OffOff_amplitudes = [];
OffOff_widths = [];
OffOff_peakDists = [];

OffOn_amplitudes = [];
OffOn_widths = [];
OffOn_peakDists = [];

OnOff_amplitudes = [];
OnOff_widths = [];
OnOff_peakDists = [];

OnOn_amplitudes = [];
OnOn_widths = [];
OnOn_peakDists = [];

% initialize a figure outside of loop
figure;

% Initialize condition-based counters
countOffOff = 1;
countOffOn = 1;
% set ramp counter (countRamp = 1)
countOnOff = 1;
countOnOn = 1;

% Loop through CSV files
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
    euclidall = euclidall * pixels_to_mm; % converting euclidean distances to mm

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
    smoothed_fTipAveBlk = smoothdata(fTipAveBlk, 'gaussian', window_Width);

    % Find peak amplitudes and compute half-widths -- findpeaks function [review documentation]
    [peaks, locs, widths, prominences] = findpeaks(smoothed_fTipAveBlk, MinPeakHeight=20, MinPeakDistance=20, MinPeakProminence=10, Annotate ='extents');

    % Convert distance variables to mm usng distance conversion factor
    amplitudes = peaks * pixels_to_mm; % converting amplitudes to mm

    % Compute timepoints from locs (vector of integer indices corresponding to video frame number)
    timepoints = locs / fps; % Convert frame numbers to time (in seconds) using video sampling rate (Fs) conversion factor

    % Compute distances between consecutive peaks
    peakDists_frames = diff(locs); % by frame indice
    peakDists = diff(timepoints); % by timepoint (in seconds)

    % Convert frame-relative variables to seconds using time conversion factor
    widths = widths / fps; % converting widths to seconds
    halfWidths = widths / 2;

    % Compute timepoints for all indices
    timepoints__fTipAveBlk = (1:length(smoothed_fTipAveBlk))/fps;

    % Plot smooth movement for each CSV iteration
    subplot(length(moveCSV), 1, csv_i);
    hold on
    % Adjust the parameters in findpeaks
    findpeaks(smoothed_fTipAveBlk, timepoints__fTipAveBlk, MinPeakHeight=20, MinPeakDistance=0.20, MinPeakProminence=10, Annotate ='extents');
    % define axes labels and subplot titles
    xlabel('time (s)');
    ylabel('amplitude');
    hold off
    title(['Smooth Hand O/C Movement, ', num2str(matName_title)])


    % Compute the mean and variability for each measurement
    mean_amplitudes(csv_i) = mean(amplitudes);
    std_amplitudes(csv_i) = std(amplitudes);
    var_amplitudes(csv_i) = var(amplitudes);

    mean_widths(csv_i) = mean(widths);
    std_widths(csv_i) = std(widths);
    var_widths(csv_i) = var(widths);

    mean_peakDists(csv_i) = mean(peakDists);
    std_peakDists(csv_i) = std(peakDists);
    var_peakDists(csv_i) = var(peakDists);

    % Store the measures to the respective array based on the video index
    if ismember(csv_i, [1, 2]) % L: sessions 1 & 3, R: sessions 2 & 4
        OffOff_amplitudes = [OffOff_amplitudes; amplitudes];
        OffOff_widths = [OffOff_widths; widths];
        OffOff_peakDists = [OffOff_peakDists; peakDists];
    elseif ismember(csv_i, [4, 5]) % L: sessions 7 & 9, R: sessions 8 & 10
        OffOn_amplitudes = [OffOn_amplitudes; amplitudes];
        OffOn_widths = [OffOn_widths; widths];
        OffOn_peakDists = [OffOn_peakDists; peakDists];
    elseif ismember(csv_i, [6, 7]) % L: sessions 13 & 15, R: sessions ...
        OnOff_amplitudes = [OnOff_amplitudes; amplitudes];
        OnOff_widths = [OnOff_widths; widths];
        OnOff_peakDists = [OnOff_peakDists; peakDists];
    elseif ismember(csv_i, [9, 10]) % L: sessions 20 & 22, R: sessions ...
        OnOn_amplitudes = [OnOn_amplitudes; amplitudes];
        OnOn_widths = [OnOn_widths; widths];
        OnOn_peakDists = [OnOn_peakDists; peakDists];
    end

    % storage condition indep of iterator (~ like while loop)
    if ismember(csv_i, [1, 2])
        % Compute the mean and variability for each measurement in the OffMed, OffStim condition
        mean_OffOff_amplitudes_i(countOffOff) = mean(OffOff_amplitudes,'omitnan');
        std_OffOff_amplitudes_i(countOffOff) = std(OffOff_amplitudes, 'omitnan');
        var_OffOff_amplitudes_i(countOffOff) = var(OffOff_amplitudes, 'omitnan');

        mean_OffOff_widths_i(countOffOff) = mean(OffOff_widths, 'omitnan');
        std_OffOff_widths_i(countOffOff) = std(OffOff_widths, 'omitnan');
        var_OffOff_widths_i(countOffOff) = var(OffOff_widths, 'omitnan');

        mean_OffOff_peakDists_i(countOffOff) = mean(OffOff_peakDists, 'omitnan');
        std_OffOff_peakDists_i(countOffOff) = std(OffOff_peakDists, 'omitnan');
        var_OffOff_peakDists_i(countOffOff) = var(OffOff_peakDists, 'omitnan');

        countOffOff = countOffOff + 1;
    end

    if ismember(csv_i, [4, 5])
        % Compute the mean and variability for each measurement in the OffMed, OnStim condition
        mean_OffOn_amplitudes_i(countOffOn) = mean(OffOn_amplitudes, 'omitnan');
        std_OffOn_amplitudes_i(countOffOn) = std(OffOn_amplitudes, 'omitnan');
        var_OffOn_amplitudes_i(countOffOn) = var(OffOn_amplitudes, 'omitnan');

        mean_OffOn_widths_i(countOffOn) = mean(OffOn_widths, 'omitnan');
        std_OffOn_widths_i(countOffOn) = std(OffOn_widths, 'omitnan');
        var_OffOn_widths_i(countOffOn) = var(OffOn_widths, 'omitnan');

        mean_OffOn_peakDists_i(countOffOn) = mean(OffOn_peakDists, 'omitnan');
        std_OffOn_peakDists_i(countOffOn) = std(OffOn_peakDists, 'omitnan');
        var_OffOn_peakDists_i(countOffOn) = var(OffOn_peakDists, 'omitnan');

        countOffOn = countOffOn + 1;
    end

    if ismember(csv_i, [6, 7])
        % Compute the mean and variability for each measurement in the OffMed, OffStim condition
        mean_OnOff_amplitudes_i(countOnOff) = mean(OnOff_amplitudes,'omitnan');
        std_OnOff_amplitudes_i(countOnOff) = std(OnOff_amplitudes, 'omitnan');
        var_OnOff_amplitudes_i(countOnOff) = var(OnOff_amplitudes, 'omitnan');

        mean_OnOff_widths_i(countOnOff) = mean(OnOff_widths, 'omitnan');
        std_OnOff_widths_i(countOnOff) = std(OnOff_widths, 'omitnan');
        var_OnOff_widths_i(countOnOff) = var(OnOff_widths, 'omitnan');

        mean_OnOff_peakDists_i(countOnOff) = mean(OnOff_peakDists, 'omitnan');
        std_OnOff_peakDists_i(countOnOff) = std(OnOff_peakDists, 'omitnan');
        var_OnOff_peakDists_i(countOnOff) = var(OnOff_peakDists, 'omitnan');

        countOnOff = countOnOff + 1;
    end

    if ismember(csv_i, [9, 10])
        % Compute the mean and variability for each measurement in the OffMed, OffStim condition
        mean_OnOn_amplitudes_i(countOnOn) = mean(OnOn_amplitudes,'omitnan');
        std_OnOn_amplitudes_i(countOnOn) = std(OnOn_amplitudes, 'omitnan');
        var_OnOn_amplitudes_i(countOnOn) = var(OnOn_amplitudes, 'omitnan');

        mean_OnOn_widths_i(countOnOn) = mean(OnOn_widths, 'omitnan');
        std_OnOn_widths_i(countOnOn) = std(OnOn_widths, 'omitnan');
        var_OnOn_widths_i(countOnOn) = var(OnOn_widths, 'omitnan');

        mean_OnOn_peakDists_i(countOnOn) = mean(OnOn_peakDists, 'omitnan');
        std_OnOn_peakDists_i(countOnOn) = std(OnOn_peakDists, 'omitnan');
        var_OnOn_peakDists_i(countOnOn) = var(OnOn_peakDists, 'omitnan');

        countOnOn = countOnOn + 1;
    end


    % Store results for each csv_i into a structure
    results(csv_i).fileName = tmpCSV;
    results(csv_i).matName = matName;
    results(csv_i).rawMovement = fTipAveBlk;
    results(csv_i).smoothMovement = smoothed_fTipAveBlk;
    results(csv_i).timepoints = timepoints;
    results(csv_i).locs = locs;
    results(csv_i).peaks = peaks;
    results(csv_i).amplitudes = amplitudes;
    results(csv_i).prominences = prominences;
    results(csv_i).widths = widths;
    results(csv_i).halfWidths = halfWidths;
    results(csv_i).peakDists = peakDists;

    results(csv_i).mean_amplitudes = mean_amplitudes(csv_i);
    results(csv_i).std_amplitudes = std_amplitudes(csv_i);
    results(csv_i).var_amplitudes = var_amplitudes(csv_i);

    results(csv_i).mean_widths = mean_widths(csv_i);
    results(csv_i).std_widths = std_widths(csv_i);
    results(csv_i).var_widths = var_widths(csv_i);

    results(csv_i).mean_peakDists = mean_peakDists(csv_i);
    results(csv_i).std_peakDists = std_peakDists(csv_i);
    results(csv_i).var_peakDists = var_peakDists(csv_i);


    % Define unique name for the results output file based on the current CSV name
    fTipTracking_results_mm = [outputDir filesep 'output_' tmpCSV(1:end-44) '.csv']; % assumes tmpCSV is a string ending in '.csv'

    % Create a table to store results based on computed variables
    T1 = table(timepoints, locs, peaks, amplitudes, prominences, widths, halfWidths, 'VariableNames', {'Timepoints', 'Locations', 'Peaks', 'Amplitudes', 'Prominences', 'Widths', 'HalfWidths'});

    % Write results table to a CSV file
    writetable(T1, fTipTracking_results_mm);


    % Define unique name for the summary results output file based on the current CSV name
    fTipTracking_results_summary_mm = [outputDir filesep 'summary_output_' tmpCSV(1:end-44) '.csv']; % assumes tmpCSV is a string ending in '.csv'

    % Create a table to store summary results
    T2 = table(mean_amplitudes(csv_i), std_amplitudes(csv_i), var_amplitudes(csv_i), ...
        mean_widths(csv_i), std_widths(csv_i), var_widths(csv_i), ...
        mean_peakDists(csv_i), std_peakDists(csv_i), var_peakDists(csv_i), ...
        'VariableNames', {'MeanAmplitude', 'StdAmplitude', 'VarAmplitude', 'MeanWidth', 'StdWidth', 'VarWidth', 'MeanPeakDist', 'StdPeakDist', 'VarPeakDist'});

    % Write summary results table to a CSV file
    writetable(T2, fTipTracking_results_summary_mm);

end

% Save results structure in MAT file
save([outputDir filesep 'fTipTracking_results_mm.mat'], 'results');


%% Plotting smooth movement comparisions

% Concatenate smoothed fTip movement data for [OffMed, OffStim condition]
concatenated_smoothed_OffOff = cat(1, results(1).smoothMovement, results(2).smoothMovement);

% Concatenate smoothed fTip movement data for videos [OffMed, OnStim condition]
concatenated_smoothed_OffOn = cat(1, results(4).smoothMovement, results(5).smoothMovement); % L sessions
% concatenated_smoothed_OffOn = cat(1, results(3).smoothMovement, results(4).smoothMovement); % R sessions

% Concatenate smoothed fTip movement data for videos [OnMed, OffStim condition]
concatenated_smoothed_OnOff = cat(1, results(6).smoothMovement, results(7).smoothMovement); % L sessions

% Concatenate smoothed fTip movement data for videos [OnMed, OnStim condition]
concatenated_smoothed_OnOn = cat(1, results(9).smoothMovement, results(10).smoothMovement); % L sessions

% Create a new time vector for concatenated data
timepoints_concatenated_OffOff = (1:length(concatenated_smoothed_OffOff))/fps;
timepoints_concatenated_OffOn = (1:length(concatenated_smoothed_OffOn))/fps;
timepoints_concatenated_OnOff = (1:length(concatenated_smoothed_OnOff))/fps;
timepoints_concatenated_OnOn = (1:length(concatenated_smoothed_OnOn))/fps;

% Plot the results
figure;

OffOff_color = [0.4 0.2 0.6]; % indigo/purple
OffOn_color = [0.2 0.7 0.8]; % teal/turquoise
OnOff_color = [0.8 0.3 0.1]; % orange
OnOn_color = [0.5 0.7 0.2]; % green

hold on;

% Plot concatenated smoothed data for videos [OffMed, OffStim condition]
plot(timepoints_concatenated_OffOff, concatenated_smoothed_OffOff, 'Color', OffOff_color);

% Plot concatenated smoothed data for videos [OnMed, OffStim condition]
plot(timepoints_concatenated_OffOn, concatenated_smoothed_OffOn, 'Color', OffOn_color);

% Plot concatenated smoothed data for videos [OffMed, OnStim condition]
plot(timepoints_concatenated_OnOff, concatenated_smoothed_OnOff, 'Color', OnOff_color);

% Plot concatenated smoothed data for videos [OnMed, OnStim condition]
plot(timepoints_concatenated_OnOn, concatenated_smoothed_OnOn, 'Color', OnOn_color);

xlabel('time (s)');
ylabel('finger movement amplitude');
legend('Off Med, Off Stim', 'Off Med, On Stim', 'On Med, Off Stim', 'On Med, On Stim');

hold off;

%% Call summarizeCondition_dstats function for each condition

T3 = summarizeCondition_dstats('OffOff', OffOff_amplitudes, OffOff_widths, OffOff_peakDists, outputDir);
T4 = summarizeCondition_dstats('OffOn', OffOn_amplitudes, OffOn_widths, OffOn_peakDists, outputDir);
T5 = summarizeCondition_dstats('OnOff', OnOff_amplitudes, OnOff_widths, OnOff_peakDists, outputDir);
T6 = summarizeCondition_dstats('OnOn', OnOn_amplitudes, OnOn_widths, OnOn_peakDists, outputDir);

% Combine the tables vertically
T7 = [T3; T4; T5; T6];

% Save the combined table to a CSV file
writetable(T7, [outputDir filesep 'fTipTracking_results-per-condition_summary_mm_v2.csv'], 'WriteRowNames', true);


%% Computing stat comparisons (between all states) - ANOVA

% Prepare amplitude data for ANOVA

% Concatenate all amplitude datasets
all_amplitudes = [OffOff_amplitudes; OffOn_amplitudes; OnOff_amplitudes; OnOn_amplitudes];

% Create corresponding group labels - ensure data and group_labels are same length
group_labels_amplitudes = [repmat({'OffOff'}, length(OffOff_amplitudes), 1);
    repmat({'OffOn'}, length(OffOn_amplitudes), 1);
    repmat({'OnOff'}, length(OnOff_amplitudes), 1);
    repmat({'OnOn'}, length(OnOn_amplitudes), 1)];


% Prepare peak width data for ANOVA

% Concatenate all peak width datasets
all_widths = [OffOff_widths; OffOn_widths; OnOff_widths; OnOn_widths];

% Create corresponding group labels - ensure data and group_labels are same length
group_labels_widths = [repmat({'OffOff'}, length(OffOff_widths), 1);
    repmat({'OffOn'}, length(OffOn_widths), 1);
    repmat({'OnOff'}, length(OnOff_widths), 1);
    repmat({'OnOn'}, length(OnOn_widths), 1)];


% Prepare peak distance data for ANOVA

% Concatenate all peak width datasets
all_peakDists = [OffOff_peakDists; OffOn_peakDists; OnOff_peakDists; OnOn_peakDists];

% Create corresponding group labels - ensure data and group_labels are same length.
group_labels_peakDists = [repmat({'OffOff'}, length(OffOff_peakDists), 1);
    repmat({'OffOn'}, length(OffOn_peakDists), 1);
    repmat({'OnOff'}, length(OnOff_peakDists), 1);
    repmat({'OnOn'}, length(OnOn_peakDists), 1)];


%% Call plotAnovaResults function for each measure

ANOVA_plot_allStates(all_amplitudes, group_labels_amplitudes, 'Amplitudes', 'Amplitude (mm)', 'Amplitude Comparison Across Conditions');
ANOVA_plot_allStates(all_widths, group_labels_widths, 'Intra-movement Durations', 'Intra-movement Durations (s)', 'Intra-movement Duration Comparison Across Conditions');
ANOVA_plot_allStates(all_peakDists, group_labels_peakDists, 'Inter-movement Durations', 'Inter-movement Durations (s)', 'Inter-movement Duration Comparison Across Conditions');


%% functions

function summaryTable = summarizeCondition_dstats(conditionName, amplitudes, widths, peakDists, outputDir)

% Compute overall mean, standard deviation, and variance
mean_amplitudes = mean(amplitudes);
std_amplitudes = std(amplitudes);
var_amplitudes = var(amplitudes);

mean_widths = mean(widths);
std_widths = std(widths);
var_widths = var(widths);

mean_peakDists = mean(peakDists);
std_peakDists = std(peakDists);
var_peakDists = var(peakDists);

% Create a table to store overall summary results
summaryTable = table(mean_amplitudes, std_amplitudes, var_amplitudes, ...
    mean_widths, std_widths, var_widths, ...
    mean_peakDists, std_peakDists, var_peakDists, ...
    'VariableNames', {'MeanAmplitude', 'StdAmplitude', 'VarAmplitude', ...
    'MeanWidth', 'StdWidth', 'VarWidth', ...
    'MeanPeakDist', 'StdPeakDist', 'VarPeakDist'});

% Assign row name to the summary table
summaryTable.Properties.RowNames = {sprintf('%s_Condition', conditionName)};

% Write summary stats table per condition to a CSV file
fileName = sprintf('%sfTipTracking_results_%s_summary_mm.csv', conditionName);
writetable(summaryTable, [outputDir filesep fileName],'WriteRowNames', true);

end


function ANOVA_plot_allStates(data, group_labels, measureName, yLabel, anovaTitle)

% Check if the lengths of data and group_labels are equal
if length(data) ~= length(group_labels)
    error('Data and group_labels must be the same length. Data length: %d, Group labels length: %d', length(data), length(group_labels));
end

% Perform ANOVA
[p_value_anova, tbl, stats] = anova1(data, group_labels, 'off');

% Display ANOVA results
disp([anovaTitle, ' ANOVA p-value: ', num2str(p_value_anova)]);
disp(tbl);

% Plot ANOVA Results
figure;
box_handle = boxplot(data, group_labels);
title([measureName, ' Comparison Across Conditions']);
ylabel(yLabel);
xlabel('Condition');

% Annotate with ANOVA p-value
x_limits = xlim;
y_limits = ylim;
text(x_limits(2) * 0.95, y_limits(2) * 0.95, ...
    sprintf('ANOVA p-value: %.3f', p_value_anova), ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'FontSize', 10, 'FontWeight', 'bold');

% Calculate means and standard deviations for annotation
unique_groups = unique(group_labels);
means = arrayfun(@(x) mean(data(strcmp(group_labels, x))), unique_groups);
stds = arrayfun(@(x) std(data(strcmp(group_labels, x))), unique_groups);

% Get positions for annotations
boxes = findobj(gca, 'Tag', 'Box');
positions = arrayfun(@(x) x.XData(2), boxes);

% Annotate with means and standard deviations
for i = 1:length(means)
    text_position = [positions(i), y_limits(2) * 0.95];
    text(text_position(1), text_position(2), ...
        sprintf('Mean=%.2f\nSD=%.2f', means(i), stds(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontSize', 8, 'FontWeight', 'bold');
end

end
