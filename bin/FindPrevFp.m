function [Fp] = FindPrevFp(Data)

SearchSteps = 3; %  numSteps+2; % add in 2 steps to ensure

%% find changes in foot on/offs
R = [Data.RightOn];
ChangeR = diff(R)~=0;
RChanges = sum(ChangeR);

L = [Data.LeftOn];
ChangeL = diff(L)~=0;
LChanges = sum(ChangeL);

%% wait for enough time and steps
% if less than 5 gait events, dont look for stance/swing times
Events = 5;
dataFrames = 150; 
if length(Data) < dataFrames 
    % if not enough time, save as NaN
    Fp.RyPeak = NaN;
    Fp.RyInd = NaN;
    Fp.LyPeak = NaN;
    Fp.LyInd = NaN;
    return
elseif RChanges < Events || LChanges < Events
    % if not enough steps, save as NaN
    Fp.RyPeak = NaN;
    Fp.RyInd = NaN;
    Fp.LyPeak = NaN;
    Fp.LyInd = NaN;
    return
end


%% RIGHT
% if currently in stance
if Data(end).RightOn == 1
    % delete force data from current step
    flip = fliplr([Data.RightOn]);
    CurrStepOn = find(flip == 0, 1);
    
    % get last foot off
    Ons = fliplr([Data.RightOn]);
    Ons(1:CurrStepOn) = 0;
    LastOff = find(Ons == 1, SearchSteps) - 1;
    if length(LastOff) > 1
        while LastOff(2) - LastOff(1) > 1
            LastOff(1) = [];
            break
        end
    end
    % get last foot on
    LastOn = find(Ons(LastOff(1)+1:end) == 0, SearchSteps);
    if LastOn(1) == 0
        LastOn(1) = [];
    end
    LastOn = LastOn + LastOff(1); % add back in search offset
    
    
else % if currently in swing

    % get last foot off
    Ons = fliplr([Data.RightOn]);
    LastOff = find(Ons == 1, SearchSteps) - 1;
    if length(LastOff) > 1
        while LastOff(2) - LastOff(1) > 1
            LastOff(1) = [];
            break
        end
    end
    % get last foot on
    LastOn = find(Ons(LastOff(1):end) == 0, SearchSteps) - 1;
    if LastOn(1) == 0
        LastOn(1) = [];
    end
    LastOn = LastOn + LastOff(1); % add back in search offset
    
end

% get overall length of data stream
Len = length(Data);
% get indicies of last stance phase only
LastStanceR = [Len-LastOn(1): Len-LastOff(1)];

% extract forces from last stance phase
Fp.Rz = [Data(LastStanceR).F1Z];
Fp.Ry = [Data(LastStanceR).F1Y];

%% LEFT
if Data(end).LeftOn == 1
    % delete force data from current step
    flip = fliplr([Data.LeftOn]);
    CurrStepOn = find(flip == 0, 1);
    
    % get last foot off
    Ons = fliplr([Data.LeftOn]);
    Ons(1:CurrStepOn) = 0;
    LastOff = find(Ons == 1, SearchSteps) - 1;
    if length(LastOff) > 1
        while LastOff(2) - LastOff(1) > 1
            LastOff(1) = [];
            break
        end
    end
    % get last foot on
    LastOn = find(Ons(LastOff(1)+1:end) == 0, SearchSteps);
    if LastOn(1) == 0
        LastOn(1) = [];
    end
    LastOn = LastOn + LastOff(1); % add back in search offset
    
    
else % if currently in swing
    
    % get last foot off
    Ons = fliplr([Data.LeftOn]);
    LastOff = find(Ons == 1, SearchSteps) - 1;
    if length(LastOff) > 1
        while LastOff(2) - LastOff(1) > 1
            LastOff(1) = [];
            break
        end
    end
    % get last foot on
    LastOn = find(Ons(LastOff(1):end) == 0, SearchSteps) - 1;
    if LastOn(1) == 0
        LastOn(1) = [];
    end
    LastOn = LastOn + LastOff(1); % add back in search offset
end

% get overall length of data stream
Len = length(Data);
% get indicies of last stance phase only
LastStanceL = [Len-LastOn(1):Len-LastOff(1)];

% extract forces from last stance phase
Fp.Lz = [Data(LastStanceL).F2Z];
Fp.Ly = [Data(LastStanceL).F2Y];

%% Plot to check values
% PlotGRFs = 'Yes';
PlotGRFs = 'No';
if strcmp(PlotGRFs, 'Yes')
    figure;
    subplot(222);
    plot(Fp.Rz);
    title('Right vertical force');
    
    subplot(224);
    plot(Fp.Ry);
    title('Right propulsive force');
    
    subplot(221);
    plot(Fp.Lz);
    title('Left vertical force');
    
    subplot(223);
    plot(Fp.Ly);
    title('Left propulsive force');
    
end

%% Calculate max
% PkProm = 100; % threshold peak prominence
% PkyProm = 10; 

% RIGHT
% vertical force peaks
% [pks, locs] = findpeaks(Fp.Rz, 'SortStr','descend',...
%     'MinPeakProminence',PkProm);
% ind = find(locs > length(Fp.Rz)/2); % find 1st peak in 2nd half of stance
% Fp.RzPeak = pks(ind);
% Fp.RzInd = locs(ind);
% % prop force peaks
% [pks, locs] = findpeaks(fliplr(-Fp.Ry), 'SortStr','descend',...
%     'MinPeakProminence',PkyProm, 'NPeaks', 1);
% Fp.RyPeak = abs(pks);
% Fp.RyInd = length(Fp.Ry) - locs;

Half = floor(length(Fp.Rz)/2);
BackHalf = Fp.Rz(Half:end);
[Fp.RzPeak, locs] = findpeaks(BackHalf, 'SortStr','descend','NPeaks',1);
Fp.RzInd = locs + Half - 1;
% prop force peaks
[Fp.RyPeak, Fp.RyInd] = max(-Fp.Ry);

% LEFT
% vertical force peaks
% [pks, locs] = findpeaks(fliplr(Fp.Lz), 'SortStr','descend',...
%     'MinPeakProminence',PkProm, 'NPeaks', 1);
% ind = find(locs > length(Fp.Lz)/2); % find 1st peak in 2nd half of stance
% Fp.LzPeak = pks(ind);
% Fp.LzInd = locs(ind);
% % prop force peaks
% [pks, locs] = findpeaks(fliplr(-Fp.Ly), 'SortStr','descend',...
%     'MinPeakProminence',PkyProm, 'NPeaks', 1);
% ind = find(locs > length(Fp.Ly)/2);
% Fp.LyPeak = abs(pks(ind));
% Fp.LyInd = locs(ind);
Half = floor(length(Fp.Lz)/2);
BackHalf = Fp.Lz(Half:end);
[Fp.LzPeak, locs] = findpeaks(BackHalf, 'SortStr','descend','NPeaks',1);
Fp.LzInd = locs + Half - 1;
% prop force peaks
% [pks, locs] = findpeaks(fliplr(-Fp.Ly), 'SortStr','descend',...
%     'MinPeakProminence',PkyProm, 'NPeaks', 1);
[Fp.LyPeak, Fp.LyInd] = max(-Fp.Ly);

% if no idenfiable prop peak, take value at peak vertical force
if isempty(Fp.RyPeak)
    if isempty(Fp.RzInd) == 0
        Fp.RyPeak = abs(Fp.Ry(Fp.RzInd));
        Fp.RyInd = Fp.RzInd;
    else
        Fp.RyPeak = NaN;
        Fp.RyInd = NaN;
    end
end
if isempty(Fp.LyPeak)
    if isempty(Fp.LzInd) == 0
        Fp.LyPeak = abs(Fp.Ly(Fp.LzInd));
        Fp.LyInd = Fp.LzInd;
    else
        Fp.LyPeak = NaN;
        Fp.LyInd = NaN;
    end
end

% delete unnecessary variables
% Fp.Lz = []; 
% Fp.Ly = []; 
% Fp.Rz = []; 
% Fp.Ry = []; 

end