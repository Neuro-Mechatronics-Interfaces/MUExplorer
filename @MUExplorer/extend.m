function eSIG = extend(SIG, extFact)
%EXTEND Extends the signals (rows) in array of signals S by adding the delayed repetitions of each signal (row). 
%
% eSIG=extend(SIG,extFact);
%
% Extends the signals (rows) in array of signals S by adding the delayed
% repetitions of each signal (row).
%
% Inputs:
%   SIG - the row-vise array of sampled signals
%   extFact - the number of delayed repetitions of each signal (row) in S
% Outputs: 
%   eSIG - extended row-vise array of signals
%
% AUTHOR: Ales Holobar, FEECS, University of Maribor, Slovenia

[r,c]=size(SIG);
eSIG=zeros(r*extFact,c+extFact-1);

for k=1:r
    for m=1:extFact
        eSIG((k-1)*extFact+m,:)=[zeros(1,m-1) SIG(k,:) zeros(1,extFact-m)];
    end
end

end