%% Script / function outline

% function [] = save_IO_EphysProcFiles(studyID, Case_DataDir)

% Goal: 
    % query rows in summaryXLSX by specific pt hemisphere/studyID (single integer correlated with StudyNum)
    % identify rows with non-empty/non-NAN cells in the trialNum column 
    % extract relevant .mat filenames in the ao_MAT_file column (% output cell array of relevant .mat filenames)
    % extract Ephys fields of interest in relevant .mat files
    % restructure relevant data into output matrix

% Required resources
    % Summary XLSX file 
        % trial IDs and mat filenames
    % Directories for raw data locs
    % Directories for saving post-processed data

%% CCC

clc
close all
clear all

%% Variable Inputs

% isolate a specific studyID
studyID = 10;

% specify directory where case-specific data files are located 
Case_DataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_31_2023'; 

% Completed cases:
% 1: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_09_2023'
% 2: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\03_23_2023'
% 3: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\04_05_2023'
% 4: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\04_13_2023'
% 5: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\04_13_2023'
     % RawDataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\04_13_2023\Raw Electrophysiology MATLAB\RH'
% 6: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_11_2023'; *ACC
% 7: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_18_2023_a'; *ACC
% 8: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_18_2023_b'
     % RawDataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_18_2023_b\Raw Electrophysiology MATLAB\LH'
% 9: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_18_2023_b'
     % RawDataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_18_2023_b\Raw Electrophysiology MATLAB\RH';
% 10: 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative\05_31_2023'; *ACC

%% Hardcode directories
IO_DataDir = 'Z:\RadcliffeE\Thesis_PD Neuro-correlated Kinematics\Data\Intraoperative';  % directory where all IO data is located
RawDataDir = [Case_DataDir, filesep, 'Raw Electrophysiology MATLAB'];                    % directory where raw MATLAB data files are located (case-specific)
ProcDataDir = [Case_DataDir, filesep, 'Processed Electrophysiology'];                    % directory where processed MATLAB data should be saved (case-specific)
mkdir(ProcDataDir);

% load XLSX file location
cd(IO_DataDir)

% load summaryXLSX table (save in GitHub repo)
summaryXLSX = readtable("Subject_AO.xlsx");

%% call main functions

% extract relevant .mat filenames in the ao_MAT_file column
mat_filelist = save_IO_mat_filenames(studyID);

% extract relevant info from relevant .mat files in mat_filelist
save_IO_mat_ProcFiles(mat_filelist, Case_DataDir);

