function [blatabase] = BDM_virtUnpack(virt)

% This function speeds up the loading of the virtual twin by prelocating
% all the information into the expected formats. Since the digital twin
% blade is very dense this allows for the data to be ready instead of
% loaded when needed.

% Main blade unpack
blatabase.blade = zeros(height(virt(:,1)),3);
blatabase.blade(:,1) = virt(:,1); blatabase.blade(:,2) = virt(:,2); blatabase.blade(:,3) = virt (:,3);

% Leading edge unpack
blatabase.lead = zeros(height(virt(~isnan(virt(:,4)))),3);
blatabase.lead(:,1) = virt(1:height(blatabase.lead(:,1)),4); blatabase.lead(:,2) = virt(1:height(blatabase.lead(:,1)),5); blatabase.lead(:,3) = virt(1:height(blatabase.lead(:,1)),6);

% Spar unpack
blatabase.spar = zeros(height(virt(~isnan(virt(:,7)))),3);
blatabase.spar(:,1) = virt(1:height(blatabase.spar(:,1)),7); blatabase.spar(:,2) = virt(1:height(blatabase.spar(:,1)),8); blatabase.spar(:,3) = virt(1:height(blatabase.spar(:,1)),9);

% Leading edge unpack
blatabase.trail = zeros(height(virt(~isnan(virt(:,10)))),3);
blatabase.trail(:,1) = virt(1:height(blatabase.trail(:,1)),10); blatabase.trail(:,2) = virt(1:height(blatabase.trail(:,1)),11); blatabase.trail(:,3) = virt(1:height(blatabase.trail(:,1)),12);

end