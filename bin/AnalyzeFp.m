function [FpData] = AnalyzeFp(InputData, bodyMass, PlotFp)

%% extract propulsive force from data structure
Ry = [InputData.F1Y];
Rz = [InputData.F1Z];
Ly = [InputData.F2Y];
Lz = [InputData.F2Z];

%% Find Peaks
PkProm = 80; % threshold peak prominence
PkWidth = 100; % threshold peak width
PkDist = 100; 
PkHt = bodyMass; % only find peaks that are ~10% of body weight (no gravity multiplication)
% RIGHT
% vertical force peaks
[FpData.RzPeaks, FpData.RzInds] = findpeaks(Rz, 'SortStr','descend',...
    'MinPeakProminence',PkProm, 'MinPeakWidth',PkWidth,...
    'MinPeakDistance', PkDist, 'MinPeakHeight', PkHt);
% prop force peaks
[FpData.RyPeaks, FpData.RyInds] = findpeaks(-Ry, 'SortStr','descend',...
    'MinPeakProminence',PkProm, 'MinPeakWidth',PkWidth, ...
    'MinPeakDistance', PkDist, 'MinPeakHeight', PkHt);
% LEFT
% vertical force peaks
[FpData.LzPeaks, FpData.LzInds] = findpeaks(Lz, 'SortStr','descend',...
    'MinPeakProminence',PkProm, 'MinPeakWidth',PkWidth, ...
    'MinPeakDistance', PkDist, 'MinPeakHeight', PkHt);
% prop force peaks
[FpData.LyPeaks, FpData.LyInds] = findpeaks(-Ly, 'SortStr','descend',...
    'MinPeakProminence',PkProm, 'MinPeakWidth',PkWidth, ...
    'MinPeakDistance', PkDist, 'MinPeakHeight', PkHt);

%% plot propulsive force
if strcmp(PlotFp, 'Yes')
    figure;
    subplot(211); hold on; 
    plot(-Ry); title('Right Propulsive Force');
    plot(FpData.RyInds, FpData.RyPeaks, 'or'); 
    subplot(212); hold on; 
    plot(-Ly); title('Left Propulsive Force');
    plot(FpData.LyInds, FpData.LyPeaks, 'or'); 
end

% calculate average Fp over warm up
FpData.RMean = mean(FpData.RyPeaks);
FpData.LMean = mean(FpData.LyPeaks);
FpData.Mean = mean([FpData.LMean, FpData.RMean]);

end