function [output] = LoadScale(signal, input)
% Output will return whatever converted input signal provided (Fx/Fy/Fz/Mx/My/Mz)
% Signal is one of Fx/Fy/Fz/Mx/My/Mz

gain = [500 500 1000 800 400 400]; % Scaling factors provided by Bertec

if strcmp(signal, 'Fx')
    output = input*gain(1);
elseif strcmp(signal, 'Fy')
    output = input*gain(2);
elseif strcmp(signal, 'Fz')
    output = input*gain(3);
elseif strcmp(signal, 'Mx')
    output = input*gain(4);
elseif strcmp(signal, 'My')
    output = input*gain(5);
elseif strcmp(signal, 'Mz')
    output = input*gain(6);  
end