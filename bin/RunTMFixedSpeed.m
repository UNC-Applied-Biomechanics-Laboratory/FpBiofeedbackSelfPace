function [Data] = CollectDataTM(Settings)

%% initalize
% if strcmp(Settings.PauseB4, 'Yes') % pause before starting trial
%     PauseSpeed = 0;
%     calllib('treadmill0x2Dremote','TREADMILL_initializeUDP','127.0.0.1','4000');
%     calllib('treadmill0x2Dremote','TREADMILL_setSpeed',PauseSpeed,PauseSpeed,.2);
%     uiwait(msgbox('Click to start Fp targeting'));
% end

% set up connections
currentSpeed = Settings.Speed; % set speed in m/s
calllib('treadmill0x2Dremote','TREADMILL_initializeUDP','127.0.0.1','4000');
calllib('treadmill0x2Dremote','TREADMILL_setSpeed',currentSpeed,currentSpeed,.2);

fprintf('Waiting for treadmill to reach walking speed... \n');
pause(5); % Wait for treadmill to reach starting speed

disp(['Treadmill set to ', num2str(currentSpeed), ' m/s']);

% Initialize cortex communication variables
initializeStruct.TalkToHostNicCardAddress = '127.0.0.1';
initializeStruct.HostNicCardAddress = '127.0.0.1';
initializeStruct.HostMulticastAddress = '225.1.1.1';
initializeStruct.TalkToClientsNicCardAddress = '0';
initializeStruct.ClientsMulticastAddress = '225.1.1.2';

% Load the SDK libraries
exitValue = mCortexExit(); %#ok<NASGU>
returnValue = mCortexInitialize(initializeStruct);
% fprintf('Loaded SDK Libraries \n');
% fprintf('Return Value = %d \n',returnValue);
if returnValue ~= 0
    errordlg('Unable to initialize ethernet communication','Sample file error');
end

%% Collect data
StopFig = figure(1);
h = uicontrol(StopFig, 'Style', 'PushButton', 'String', 'Stop', ...
    'Callback', 'delete(gcbo)','Position',[20 20 400 400]);

FeedbackFig = figure(2);

disp('Starting Trial');
tic; % start timer
startTime = datevec(now); % create elapsed timer

%% Controller Loop, stops with button click
Frame = 1;
k = 1;
while isempty(h) == 0
    drawnow;
    frameOfData = mGetCurrentFrame();
    timer = toc;
    data = frameOfData;
    
    
    if data.iFrame>Frame
        k = k+1;
        Frame = data.iFrame;
        
        F1Y = data.AnalogData.AnalogSamples(4,:);
        F1y = LoadScale('Fy', bits2volts(F1Y));
        F1Z = data.AnalogData.AnalogSamples(5,:);
        F1z = LoadScale('Fz', bits2volts(F1Z));
        F2Y = data.AnalogData.AnalogSamples(11,:);
        F2y = LoadScale('Fy', bits2volts(F2Y));
        F2Z = data.AnalogData.AnalogSamples(12,:);
        F2z = LoadScale('Fz', bits2volts(F2Z));
        
        %% Save Treadmill data in structure
        % save force data in structure
        Data(k).AnalogForces = frameOfData.AnalogData.Forces;
        Data(k).Frame = frameOfData.iFrame;
        % uncomment to save all cortex frame data
        %             Data(k).FrameData = frameOfData;
        % save converted forces (in N)
        Data(k).F1Y = F1y;
        Data(k).F1Z = F1z;
        Data(k).F2Y = F2y;
        Data(k).F2Z = F2z;
        
        % save speed
        %         Data(k).SmoothSpeed = smoothedSpeed;
        
        % save whether time point is swing or stance for left and right
        Thresh = 100; % threshold for determining if a true vGRF
        if sum(Data(k).F1Z) > Thresh
            Data(k).RightOn = 1;
        else
            Data(k).RightOn = 0;
        end
        if sum(Data(k).F2Z) > Thresh
            Data(k).LeftOn = 1;
        else
            Data(k).LeftOn = 0;
        end
        
        %% Get current time
        currTime = datevec(now);
        ElapsedTime = etime(currTime, startTime);
        
        
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
        Lo = Settings.NormFp * 0.5;
        Hi = Settings.NormFp * 1.5;
        ax.YLim = [Lo Hi];
        
        
        % put elapsed time in contolfig
        set(0,'CurrentFigure',StopFig)
        TimeStr = [num2str(floor(ElapsedTime)), ' seconds elapsed'];
        p = uipanel('Title',TimeStr, 'FontSize',12,...
            'BackgroundColor','white',...
            'Position',[.25 .1 .67 .67]);
        uicontrol(p, 'Style', 'PushButton', 'String', 'Stop', ...
            'Callback', 'delete(gcbo)','Position',[20 20 200 200]);
        
    end
    
    %% delete handle when time limit reached
    if timer > Settings.Duration
        h = [];
        StopFig = [];
    end
    
end

%% stop treadmill after handle deleted
% if strcmp(Settings.StopAfter, 'Yes')

disp('Stopping Treadmill');
speed = 0;
calllib('treadmill0x2Dremote','TREADMILL_initializeUDP','127.0.0.1','4000');
calllib('treadmill0x2Dremote','TREADMILL_setSpeed',speed, speed,.2);
close all;
% end


end