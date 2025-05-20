function PNR = estimatePNR(MUPulses,IPT,fsamp, options)
%ESTIMATEPNR  Estimates the pulse-to-noise ratio (PNR) 
%
% Syntax:
%   PNR = MUExplorer.estimatePNR(MUPulses, IPT, fsamp);
%   PNR = MUExplorer.estimatePNR(MUPulses, IPT, fsamp, 'Name', value, ...);
%
% Inputs:
%   MUPulses (1,:) {mustBePositive, mustBeInteger} - Sample instants for 1 MUAP
%   IPT (1,:) double             - Impulse train for 1 MUAP
%   fsamp (1,1) {mustBePositive} - Sample rate
%
% Options:
%   'ConditioningNoiseBandwidth' (1,1) double = 1e-6; - Minimum amount to normalize pulse power by.
%
% See also: Contents

arguments
    MUPulses (1,:) {mustBePositive, mustBeInteger}
    IPT (1,:) double
    fsamp (1,1) {mustBePositive}
    options.ConditioningNoiseBandwidth (1,1) double = 1e-6;
end

if ~isempty(MUPulses)
    
    surrogatePulseSamples = [];
    for t = -round(3/2048*fsamp):round(3/2048*fsamp)
        surrogatePulseSamples = [surrogatePulseSamples MUPulses+t]; %#ok<AGROW>
    end
    
    nInd = setdiff(MUPulses(1):MUPulses(end),surrogatePulseSamples);
    IPT = IPT/mean(IPT(MUPulses));
    
    tmpn = IPT(nInd);
    tmpn = tmpn(~isnan(tmpn));
    tmpn = tmpn(tmpn>=0);
    powerOutsidePulses = max(mean(tmpn.^2), options.ConditioningNoiseBandwidth);
    powerInsidePulses = mean(IPT(MUPulses).^2);
    PNR = round(10*10*log10(  powerInsidePulses / powerOutsidePulses))/10;
else
    PNR = 0;
end

end