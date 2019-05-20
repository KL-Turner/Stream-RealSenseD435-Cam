function [] = AnalyzeRealSenseData()
%________________________________________________________________________________________________________________________
% Written by Kevin L. Turner
% The Pennsylvania State University, Dept. of Biomedical Engineering
% https://github.com/KL-Turner
%________________________________________________________________________________________________________________________
%
%   Purpse:
%________________________________________________________________________________________________________________________
%
%   Inputs:
%
%   Outputs:
%
%   Last Revised: 
%________________________________________________________________________________________________________________________

clear
clc

rsColorizedDepthStackDirectory = dir('*ColorizedDepthStack.mat');
rsColorizedDepthStackFiles = {rsColorizedDepthStackDirectory.name}';
rsColorizedDepthStackFiles = char(rsColorizedDepthStackFiles);

rsRGBStackDirectory = dir('*RGBStack.mat');
rsRGBStackFiles = {rsRGBStackDirectory.name}';
rsRGBStackFiles = char(rsRGBStackFiles);

rsTrueDepthStackDirectory = dir('*TrueDepthStack.mat');
rsTrueDepthStackFiles = {rsTrueDepthStackDirectory.name}';
rsTrueDepthStackFiles = char(rsTrueDepthStackFiles);

%% Draw ROIs for motion tracking
disp('Verifying that ROIs exist for each day...'); disp(' ')
for a = 1:size(rsColorizedDepthStackFiles, 1)
    rsColorizedDepthStackFile = rsColorizedDepthStackFiles(a,:);
    delimiters = strfind(rsColorizedDepthStackFile, '_');
    date = rsColorizedDepthStackFile(1:delimiters(4) - 1);
    roiFile = [date '_ROIs.mat'];
    if ~exist(roiFile)
        disp(['Loading ' rsColorizedDepthStackFile '...']); disp(' ')
        load(rsColorizedDepthStackFile)
        [ROIs] = DrawAnalysisROIs(RS_ColorizedDepthStack);
        save(roiFile, 'ROIs')
    end
end

%% Load the colorized depth stack camera frames, create .avi movies from data
for b = 1:size(rsColorizedDepthStackFiles, 1)
    rsColorizedDepthStackFile = rsColorizedDepthStackFiles(b,:);
    disp(['Creating ColorizedDepthStack .AVI files... (' num2str(b) '/' num2str(size(rsColorizedDepthStackFiles, 1)) ')']); disp(' ')
    ConvertRealSenseToAVI(rsColorizedDepthStackFile, 'ColorizedDepthStack');
end

%% Load the RGB stack camera frames, create .avi movies from data
for c = 1:size(rsRGBStackFiles, 1)
    rsRGBStackFile = rsRGBStackFiles(c,:);
    disp(['Creating RGB Stack .AVI files... (' num2str(c) '/' num2str(size(rsRGBStackFiles, 1)) ')']); disp(' ')
    ConvertRealSenseToAVI(rsRGBStackFile, 'RGBStack');
end

%% Process the true depth stack frames until binarization-based processing
for d = 1:size(rsTrueDepthStackFiles, 1)
    rsTrueDepthStackFile = rsTrueDepthStackFiles(d,:);
    disp(['Processing TrueDepthStack file... (' num2str(d) '/' num2str(size(rsTrueDepthStackFiles, 1)) ')']); disp(' ')
    if ~exist([rsTrueDepthStackFile(1:end - 19) '_HalfProcDepthStack.mat'])
        disp(['Processing video from ' rsTrueDepthStackFile '...']); disp(' ')
        load(rsTrueDepthStackFile);
        delimiters = strfind(rsTrueDepthStackFile, '_');
        date = rsTrueDepthStackFile(1:delimiters(4) - 1);
        roiFile = [date '_ROIs.mat'];
        load(roiFile)
        [RS_HalfProcDepthStack, ROIs] = CorrectRealSenseFrames(RS_TrueDepthStack, ROIs);
        disp(['Saving ' rsTrueDepthStackFile(1:end - 19) '_HalfProcDepthStack.mat...']); disp(' ')
        save(roiFile, 'ROIs')
        save([rsTrueDepthStackFile(1:end - 19) '_HalfProcDepthStack.mat'], 'RS_HalfProcDepthStack', '-v7.3')
    else
        disp([rsTrueDepthStackFile(1:end - 19) '_HalfProcDepthStack.mat already exists. Continuing...']); disp(' ')
    end
end

rsHalfProcDepthStackDirectory = dir('*HalfProcDepthStack.mat');
rsHalfProcDepthStackFiles = {rsHalfProcDepthStackDirectory.name}';
rsHalfProcDepthStackFiles = char(rsHalfProcDepthStackFiles);

%% Load the colorized depth stack camera frames, create .avi movies from data
for e = 1:size(rsHalfProcDepthStackFiles, 1)
    rsHalfProcDepthStackFile = rsHalfProcDepthStackFiles(e,:);
    disp(['Creating halfway-processed depth stack .AVI files... (' num2str(e) '/' num2str(size(rsHalfProcDepthStackFiles, 1)) ')']); disp(' ')
    ConvertRealSenseToAVI(rsHalfProcDepthStackFile, 'HalfProcDepthStack');
end

%% Overlay original color onto image mask
for f = 1:size(rsHalfProcDepthStackFiles, 1)
    rsHalfProcDepthStackFile = rsHalfProcDepthStackFiles(f,:);
    rsTrueDepthStackFile = [rsHalfProcDepthStackFile(1:end - 23) '_TrueDepthStack.mat'];
    disp(['Processing halfway-processed depth stack files... (' num2str(f) '/' num2str(size(rsHalfProcDepthStackFiles, 1)) ')']); disp(' ')
    if ~exist([rsHalfProcDepthStackFile(1:end - 23) '_FullyProcDepthStack.mat'])
        disp(['Processing video from ' rsHalfProcDepthStackFile '...']); disp(' ')
        load(rsHalfProcDepthStackFile);
        load(rsTrueDepthStackFile);
        [RS_FullyProcDepthStack] = FinishRealSenseFrames(RS_TrueDepthStack, RS_HalfProcDepthStack);
        disp(['Saving ' rsHalfProcDepthStackFile(1:end - 23) '_FullyProcDepthStack.mat...']); disp(' ')
        save([rsHalfProcDepthStackFile(1:end - 23) '_FullyProcDepthStack.mat'], 'RS_FullyProcDepthStack', '-v7.3')
    else
        disp([rsHalfProcDepthStackFile(1:end - 23) '_FullyProcDepthStack.mat already exists. Continuing...']); disp(' ')
    end
end

rsFullyProcDepthStackDirectory = dir('*FullyProcDepthStack.mat');
rsFullyProcDepthStackFiles = {rsFullyProcDepthStackDirectory.name}';
rsFullyProcDepthStackFiles = char(rsFullyProcDepthStackFiles);

%% Load the fully-processed depth stack camera frames, create .avi movies from data
for g = 1:size(rsFullyProcDepthStackFiles, 1)
    rsFullyProcDepthStackFile = rsFullyProcDepthStackFiles(g,:);
    disp(['Creating fully-processed depth stack .AVI files... (' num2str(g) '/' num2str(size(rsFullyProcDepthStackFiles, 1)) ')']); disp(' ')
    ConvertRealSenseToAVI(rsFullyProcDepthStackFile, 'FullyProcDepthStack');
end

%% Track object height
for h = 1:size(rsFullyProcDepthStackFiles, 1)
    rsFullyProcDepthStackFile = rsFullyProcDepthStackFiles(h,:);
    disp(['Tracking mouse height in fully-processed depth stack... (' num2str(h) '/' num2str(size(rsFullyProcDepthStackFiles, 1)) ')']); disp(' ')
    TrackObjectHeight(rsFullyProcDepthStackFile);
end

%% Track object motion in video
% [] = TrackObjectMotion()
close all
disp('RealSense movie analysis - complete'); disp(' ')

end