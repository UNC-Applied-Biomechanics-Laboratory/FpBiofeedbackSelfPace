function [voltage] = bits2volts(code)

peak = 5;
range = peak*2;
gain = 1;
reso = 16; %NI box resolution = 16 bits

codewidth = range/(gain * (2^reso));

voltage = code * codewidth; %- peak/gain;