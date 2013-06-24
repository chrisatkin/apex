%% Advanced Planning Experiment/Fractal
%%
% <<apex-logo.png>>
%
%% Introduction
% This is the online documentation for the _Advanced Planning
% Experiment/Fractal_, or *APEX/F*.
%
%% Bootstrapping
% The first step that occurs is the bootstrapping process, located in 
% |./bootstrap.m|. The bootstrap clears the workspace (so make sure
% you've saved everything you need), adds the appropriate directories
% to the path, and loads in scan data. The default bootstrap loads DICOM
% images, although any greyscale data can be loaded (note that RGB data
% is not supported in the current version of APEX). Slides should be
% stored as an x × y × n array, where x and y refer to the horizontal
% and vertical dimensions of the scans (each slide must be of the same
% dimension) and n refers to the number of scans. Developers can use the 
% dir_contents function to list files within a directory; this data is
% a cell array of type char.
%% Architecture
% There are four key parts of APEX/F.
%
% * The |apex| function creates a user interface and sets up callbacks
% * <Viewer.html |Viewer|> is the top level in the APEX graphical stack. It is an
% abstraction for all the CT scans in the system and mainly provides
% routing to individual |Slice| objects.
% * <Slice.html |Slice|> objects contain many |Layer| s. They are an
% abstraction of an individual CT scan.
% * <Layer.html |Layer|> (and the subclasses <BitmapLayer.html
% |BitmapLayer.html|>, <PointLayer.html |PointLayer|> and
% <InterpolationLayer |InterpolationLayer|>) are the lowest level in the
% APEX graphical stack. They break down individual types of functionality
% into different classes.
%
% A typical request (for example, an action is captured as part of an event
% listener attached to a |Layer|) and travels down the graphical stack in a
% similar fasion to layer encapsulation in networking. Most requests
% execute in the scope of the layer.
%
%%
% <<general-arch.png>>
%
%% APEX/F Documentation
%
% * <bootstrap.html Architecture and Bootstrapping>
% * <Viewer.html Viewer>
% * <Slice.html Slice>
% * <Layer.html Layer>
% * <BitmapLayer.html BitmapLayer>
% * <PointLayer.html PointLayer>
% * <InterpolationLayer.html InterpolationLayer>
%
%% Setup the environment
clc
clear all
clear java
clear classes

disp('------------------------------')
disp('This is APEX/F v2.3')
disp('------------------------------')

addpath(fullfile('assets'));
addpath(fullfile('system'));
addpath(fullfile('system', 'viewer'));
addpath(fullfile('system', 'spinner'));

%% Select the correct data directory to use
%data_dir = fullfile(pwd, '..', 'data');
data_dir = uigetdir(pwd);

if data_dir == 0
    disp('No data directory, quitting...')
    return
end

fprintf('Using data in %s \n', data_dir)

%% Load the scan data from |data_dir|
dir_contents = dir_contents(data_dir);
slides = cell(1, numel(dir_contents));
bar = waitbar(0, 'Loading slides...');
for i = 1 : numel(dir_contents)
%     slides{i} = imread(fullfile(data_dir, dir_contents{i}));
	slides{i} = dicomread(fullfile(data_dir, dir_contents{i}));
    waitbar(i / numel(dir_contents), bar, 'Loading slides...');
end
close(bar);

%% Load interface
apex(slides);