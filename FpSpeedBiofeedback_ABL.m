%% Fp and Speed Biofeedback Script
% Ricky Pimentel 
% Applied Biomechanics Lab = UNC Chapel Hill
% September 2020

%% Initialize Treadmill Control
clear; clc; close all; warning off;

% change directory and load libraries
cd('C:\ABL_Documents\ABL User-Driven Treadmill Documents\TM_Controller_RTspeed');
addpath(genpath('bin'));
loadlibrary('treadmill0x2Dremote.dll','treadmill0x2Dremote.h');
loadlibrary('Cortex_SDK.dll','MatlabCortex.h');
fprintf('Loaded Libraries \n');

% Input intial conditions
prompt = {'Subject Name','Enter feedback side (L,R,N):',...
    'Enter Camera Rate:','Enter Body Weight (kg):', 'Enter normal walking speed (m/s)'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'Subj000','N','100','80', '1'}; %DEFAULT ANSWERS
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
% assign input answers to variables
SubjName = answer{1};
feedbackLeg = answer{2};
frameRate = str2double(answer{3});
bodyMass = str2double(answer{4});
normSpeed = str2double(answer{5});

targetLevels = [0.8, 0.9, 1, 1.1, 1.2]; % define targeting levels
speedTargets = normSpeed*targetLevels; % define speeds to target
TrialNames = {'M20','M10','Norm','P10','P20'};
NumTrials = length(targetLevels);

SpeedOrder = randperm(NumTrials); 
SpeedOrderNames = TrialNames(SpeedOrder)

ForceOrder = randperm(NumTrials); 
ForceOrderNames = TrialNames(ForceOrder)

trialnames = {'M20','P20'}; 
FixedSpdTargetFpOrder = randperm(2); 
FixedSpdTargetFpNames = trialnames(FixedSpdTargetFpOrder);

%% Warm up at typical walking speed
% pause before start
uiwait(msgbox('Click to start warm up at typical speed'));

% define input settings
Settings.Duration = 180;
% Settings.Duration = 60;
Settings.Speed = normSpeed;
Settings.StopAfter = 'Yes';
Settings.PauseB4 = 'No';
% Settings.Biofeedback = 'none';
Settings.Biofeedback = 'Time';
Settings.FrameRate = frameRate; 

% run TM
[WarmUpData] = FixedSpeedTM(Settings);

% analyze warm up force data
TypicalFp = AnalyzeFp(WarmUpData, bodyMass, 'Yes'); 
TypicalFp.NormMean = TypicalFp.Mean / (bodyMass * 9.81); 

disp(['Typical Propulsive Force = ', num2str(TypicalFp.Mean), ' N']);
disp(['Normalized Typical Propulsive Force = ', num2str(round(100*TypicalFp.NormMean)), '% body mass']); 

%% Self pace mode warm up
close all; clc;
dbstop if error
% pause before start
uiwait(msgbox('Click to start self-pace mode warm up'));

% input settings for self-pace mode
% Settings.Duration = 60; % duration in seconds
Settings.Duration = 180; % duration in seconds
Settings.Biofeedback = 'Fp';
Settings.TargetFp = TypicalFp.Mean;
Settings.NormFp = TypicalFp.Mean;
Settings.StartSpeed = normSpeed; 
Settings.StopAfter = 'Yes';
Settings.FrameRate = frameRate; 

% Run self pace mode
SelfPaceTestData = SelfPaceTM(Settings);

%% look for lags in biofeedback 
figure; 
plot([SelfPaceTestData.MeanPeakFp], '.', 'LineWidth', 2)
figure; 
plot([SelfPaceTestData.Time], '.', 'LineWidth', 2)
Time = [SelfPaceTestData.Time];
TimeDiff = Time(2:end) - Time(1:end-1); 
figure; plot(TimeDiff)

%% Plot self pace mode data
figure; plot([SelfPaceTestData.CoP1y] .* [SelfPaceTestData.RightOn], '.');
hold on; plot([SelfPaceTestData.CoP2y] .* [SelfPaceTestData.LeftOn], '.');

BothOn = logical([SelfPaceTestData.RightOn] + [SelfPaceTestData.LeftOn] >1); 
AvgCoP = mean([[SelfPaceTestData.CoP1y]; [SelfPaceTestData.CoP2y]]); 
AvgCoP(BothOn==0) = NaN; 

plot(AvgCoP, 'LineWidth', 2); 
plot([SelfPaceTestData.Speed], 'LineWidth', 2)

MidTM = 0.87; 
Window = 0.15; 
x = 1:length(BothOn); 
MidLine = ones(1,length(x)) .* MidTM; 
TopLine = ones(1,length(x)) .* (MidTM + Window); 
BottomLine = ones(1,length(x)) .* (MidTM - Window);

plot(x, MidLine, 'k'); 
plot(x, TopLine, 'k'); 
plot(x, BottomLine, 'k'); 
ylabel('Treadmill Length (m) and Walking Speed (m/s)'); 
xlabel('Frame');
title('Self Pace CoP and Speed'); 
legend({'right CoP','left CoP','avg CoP','speed', 'Center & Dead Zone'}); 


%% Fixed Speed in Randomized Order
close all; clc; 

SpeedTarget(NumTrials).Data = [];
SpeedTarget(NumTrials).Lvl = [];
counter = 0; 

for i = SpeedOrder
    
    % pause before next phase
    uiwait(msgbox('Click to start speed targeting'));
    
    % display trial info
    counter = counter + 1; 
    disp(' ');
    disp(['Trial ',num2str(counter)]); 
    disp(' ');
    disp(['Targeting ',num2str(speedTargets(i)), ' m/s']);
    disp(' ');
    
    % input settings for self-pace mode
    Settings.Duration = 300; % duration in seconds
%     Settings.Duration = 120;
    Settings.Speed = speedTargets(i);
    Settings.FrameRate = frameRate; 
    Settings.Biofeedback = 'Time';
    
    SpeedTarget(i).Lvl = targetLevels(i);
    SpeedTarget(i).Speed = speedTargets(i);
    
    % Run treadmill and save data
    SpeedTarget(i).Data = FixedSpeedTM(Settings);
    
end

%% Analyze Speed Data
for i = 1:NumTrials
    SpeedTarget(i).FpData = AnalyzeFp(SpeedTarget(i).Data, bodyMass, 'Yes');
    
    FpTargets(1,i) = SpeedTarget(i).FpData.Mean; 
    FpTargets(2,i) = SpeedTarget(i).FpData.Mean / TypicalFp.Mean; 
    
    
end


%% Fp Targeting in Randomized Order
close all;
    
FpTarget(NumTrials).Data = [];
FpTarget(NumTrials).Lvl = [];
counter = 0; 

for i = ForceOrder
    
     % pause before next phase
    uiwait(msgbox('Click to start Fp targeting'));
    
    % display trial info
    counter = counter + 1; 
    disp(' ');
    disp(['Trial ',num2str(counter)]); 
    disp(' ');
    disp(['Targeting ',num2str(FpTargets(1,i)), ' N']);
    disp(' ');
    
    % input settings for self-pace mode
    Settings.Duration = 300; % duration in seconds
%     Settings.Duration = 180;
    Settings.TargetFp = FpTargets(1,i);
    Settings.NormFp = TypicalFp.Mean;
    Settings.Biofeedback = 'Fp';
    Settings.FrameRate = frameRate; 
    
    FpTarget(i).Lvl = targetLevels(i);
    FpTarget(i).TargetFp = FpTargets(1,i);
    
    % Run self pace mode and save data
    FpTarget(i).Data = SelfPaceTM(Settings);
    
end

%% Fixed Typical Speed with High and low Fp targeted biofeedback 
close all; clc; 
SpeedTargets = speedTargets([1 5]); 
FpTargetsFixed = FpTargets(1,[1 5]);

FixedSpdTargetFp(NumTrials).Data = [];
FixedSpdTargetFp(NumTrials).Lvl = [];
counter = 0; 

for i = FixedSpdTargetFpOrder
    
    % pause before next phase
    uiwait(msgbox('Click to start speed targeting'));
    
    % display trial info
    counter = counter + 1; 
    disp(' ');
    disp(['Trial ',num2str(counter)]); 
    disp(' ');
    disp(['Targeting ',num2str(FpTargetsFixed(1,i)), ' N']);
    disp(' ');
    
    % input settings for self-pace mode
        Settings.Duration = 300; % duration in seconds
    Settings.Speed = normSpeed;
    Settings.StopAfter = 'No'; 
    Settings.PauseB4 = 'Yes';
    Settings.Biofeedback = 'Fp';
    Settings.TargetFp = FpTargetsFixed(1,i);
    Settings.NormFp = TypicalFp.Mean;
    Settings.FrameRate = frameRate; 
    
    FixedSpdTargetFp(i).Lvl = targetLevels(i);
    FixedSpdTargetFp(i).Speed = speedTargets(i);
    
    % Run treadmill and save data
    FixedSpdTargetFp(i).Data = FixedSpeedTM(Settings);
    
end


%% Export Results?
exitValue = mCortexExit();
FileName = strcat(SubjName, '.mat'); 
save(FileName)



