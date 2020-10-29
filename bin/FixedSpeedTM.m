function [Data] = FixedSpeedTM(Settings)

%% Define IP addresses
% IP.Talk2HostNic = '10.1.1.192'; %Cortex computer top port
% IP.HostNic = '10.1.1.198'; %Processing computer top port
IP.Treadmill = '127.0.0.1'; 
IP.Talk2HostNic = '127.0.0.1'; 
IP.HostNic = '127.0.0.1';

%% Connect to Treadmill and set initial speed
currentSpeed = Settings.Speed; % set speed in m/s
r0 = calllib('treadmill0x2Dremote','TREADMILL_initializeUDP',IP.Treadmill,'4000');
r1 = calllib('treadmill0x2Dremote','TREADMILL_setSpeed',currentSpeed,currentSpeed,.25);
if r0 ~= 0 || r1 ~= 0
    disp('Treadmill Connection Error');
else
    disp('Connected to Treadmill'); 
    fprintf('Waiting for treadmill to reach walking speed... \n');
    pause(5); % Wait for treadmill to reach starting speed
    disp(['Treadmill set to ', num2str(currentSpeed), ' m/s']);
end

%% Connect to Cortex
% Initialize cortex communication variables
initializeStruct.TalkToHostNicCardAddress = IP.Talk2HostNic;
initializeStruct.HostNicCardAddress = IP.HostNic;
initializeStruct.HostMulticastAddress = '225.1.1.1';
initializeStruct.TalkToClientsNicCardAddress = '0';
initializeStruct.ClientsMulticastAddress = '225.1.1.2';

% Load the SDK libraries
r = mCortexExit();
returnValue = mCortexInitialize(initializeStruct);
if returnValue ~= 0
    errordlg('Unable to initialize ethernet communication','Sample file error');
else
    disp('Connected to Cortex'); 
end

%% Initialize data structure and figures
Frame = 1;
k = 0;

L = Settings.FrameRate .* Settings.Duration; 
Data = struct([]); 
% Data(L).AnalogForces = [];
Data(L).Frame = [];
Data(L).F1Y = []; 
Data(L).F1Z = []; 
Data(L).F2Y = []; 
Data(L).F2Z = []; 
Data(L).CoP1y = []; 
Data(L).CoP2y = []; 
Data(L).CoP1x = []; 
Data(L).CoP2x = []; 
Data(L).RightOn = []; 
Data(L).LeftOn = []; 
Data(L).Time = []; 
Data(L).Speed = [];
Data(L).Fp = [];
Data(L).MeanPeakFp = [];

StopFig = figure(1);
uicontrol(StopFig, 'Style', 'PushButton', 'String', 'Exit Figure to Stop', ...
    'Callback', 'delete(gcbo)','Position',[20 20 100 100]);

FeedbackFig = figure(2);
set(FeedbackFig, 'Position',[1000 100 800 550]); % create biofeedback figure

disp('Starting Trial');
tic; % start timer
startTime = datevec(now); % create elapsed timer

%% Fixed Speed Treadmill Controller Loop
% stops with button click
while isempty(StopFig) == 0
    drawnow;
    f = mGetCurrentFrame();
    timer = toc;   
    
    if f.iFrame>Frame
        k = k+1;
        Frame = f.iFrame;
        
        % extract analog forces
        F1Y = f.AnalogData.AnalogSamples(4,:);
        F1y = LoadScale('Fy', bits2volts(F1Y));
        F1Z = f.AnalogData.AnalogSamples(5,:);
        F1z = LoadScale('Fz', bits2volts(F1Z));
        F2Y = f.AnalogData.AnalogSamples(11,:);
        F2y = LoadScale('Fy', bits2volts(F2Y));
        F2Z = f.AnalogData.AnalogSamples(12,:);
        F2z = LoadScale('Fz', bits2volts(F2Z));
        
        %% Save Treadmill data in structure
        % save force data in structure
%         Data(k).AnalogForces = frameOfData.AnalogData.Forces;
        Data(k).Frame = f.iFrame;
        % uncomment to save all cortex frame data
        %             Data(k).FrameData = frameOfData;
        
        % save converted forces (in N)
        Data(k).F1Y = F1y;
        Data(k).F1Z = F1z;
        Data(k).F2Y = F2y;
        Data(k).F2Z = F2z;
        
        % save CoPs
        Data(k).CoP1y = mean(f.AnalogData.Forces(3,1:2:end));
        Data(k).CoP2y = mean(f.AnalogData.Forces(3,2:2:end));
        Data(k).CoP1x = mean(f.AnalogData.Forces(4,1:2:end));
        Data(k).CoP2x = mean(f.AnalogData.Forces(4,2:2:end));
        
        % save whether time point is swing or stance for left and right
        Thresh = 25; % threshold for determining if a true vGRF
        if mean(Data(k).F1Z) > Thresh
            Data(k).RightOn = 1;
        else
            Data(k).RightOn = 0;
        end
        if mean(Data(k).F2Z) > Thresh
            Data(k).LeftOn = 1;
        else
            Data(k).LeftOn = 0;
        end
        
        %% Get current time
        currTime = datevec(now);
        ElapsedTime = etime(currTime, startTime);
        Data(k).Time = ElapsedTime; 
        
    end
    
    %% Fp Biofeedback if desired
    if strcmp(Settings.Biofeedback, 'Fp') && length(Data) > 50
        
        % find peak propulsive force from previous step
        [Fp] = FindPrevFp(Data);
        MeanPeakFp = mean([Fp.LyPeak, Fp.RyPeak]);
        Data(k).Fp = Fp;
        Data(k).MeanPeakFp = MeanPeakFp;
        
        % plot biofeedback
        set(0,'CurrentFigure',FeedbackFig)
        
        plot([0 1 2] ,[Settings.TargetFp Settings.TargetFp  Settings.TargetFp],...
            '-k', 'LineWidth',2);
        hold on;
        L = plot([0 1 2],[MeanPeakFp MeanPeakFp MeanPeakFp],...
            '-k', 'LineWidth',4);
        if abs(1 - MeanPeakFp / Settings.TargetFp) > 0.05
            L.Color = 'r';
        else
            L.Color = 'g';
        end
        hold off;
        
        if ElapsedTime < 60
            TitleStr = 'Fixed Speed';
        elseif ElapsedTime >= 60 && ElapsedTime < 120
            TitleStr = 'Fixed Speed - 1 min elapsed';
        elseif ElapsedTime >= 120 && ElapsedTime < 180
            TitleStr = 'Fixed Speed - 2 min elapsed';
        elseif ElapsedTime >= 180 && ElapsedTime < 240
            TitleStr = 'Fixed Speed - 3 min elapsed';
        elseif ElapsedTime >= 240
            TitleStr = 'Fixed Speed - 4 min elapsed';
        end
        title(TitleStr);
        
        ax = gca; % edit axes
        ax.XTick = [];
        ax.YTick = [];
        Lo = Settings.NormFp * 0.5;
        Hi = Settings.NormFp * 1.5;
        ax.YLim = [Lo Hi];
        
        % put elapsed time in contolfig
        if ishandle(StopFig)
            set(0,'CurrentFigure',StopFig)
            TimeStr = [num2str(floor(ElapsedTime)), ' seconds elapsed'];
            uipanel('Title',TimeStr, 'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[.25 .1 .5 .5]);
        else
            break
        end
    
    end
    
    %% Time Biofeedback if desired
    if strcmp(Settings.Biofeedback, 'Time') && length(Data) > 50
        
        % plot biofeedback
        set(0,'CurrentFigure',FeedbackFig)
        
        if ElapsedTime < 60
            TitleStr = 'Fp Targeting';
        elseif ElapsedTime >= 60 && ElapsedTime < 120
            TitleStr = 'Fp Targeting - 1 min elapsed';
        elseif ElapsedTime >= 120 && ElapsedTime < 180
            TitleStr = 'Fp Targeting - 2 min elapsed';
        elseif ElapsedTime >= 180 && ElapsedTime < 240
            TitleStr = 'Fp Targeting - 3 min elapsed';
        elseif ElapsedTime >= 240
            TitleStr = 'Fp Targeting - 4 min elapsed';
        end
        title(TitleStr);
        
        ax = gca; % edit axes
        ax.XTick = [];
        ax.YTick = [];
%         Lo = Settings.NormFp * 0.5;
%         Hi = Settings.NormFp * 1.5;
%         ax.YLim = [Lo Hi];
        
        % put elapsed time in contolfig
        if ishandle(StopFig)
            set(0,'CurrentFigure',StopFig)
            TimeStr = [num2str(floor(ElapsedTime)), ' seconds elapsed'];
            uipanel('Title',TimeStr, 'FontSize',12,...
                'BackgroundColor','white',...
                'Position',[.25 .1 .5 .5]);
        else
            break
        end
    
    end
    
      %% No biofeedback settings
    if strcmp(Settings.Biofeedback, 'none')
        close(FeedbackFig);
    end
    
    %% delete handle when time limit reached
    if timer > Settings.Duration
        close(StopFig);
        disp('Trial Duration Reached');
        break
    end
    
end

%% stop treadmill after handle deleted
disp('Stopping Treadmill');
speed = 0;
calllib('treadmill0x2Dremote','TREADMILL_initializeUDP',IP.Treadmill,'4000');
calllib('treadmill0x2Dremote','TREADMILL_setSpeed',speed, speed,.25);
close all;

% remove 1st row if empty
if isempty(Data(1).Frame)
    Data(1) = []; 
end

% remove empty rows at end
F = length([Data.Frame]) + 1;
if length(Data) > F
    Data(F:end) = []; 
end


end