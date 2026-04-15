function BDM_case1_vis_wtclick(h, ~, hAx, wtID, tabDmg, blen, virt)
% Interaction with the WT in the park plot

% De-highlighting the previous WT
try
	hAx.UserData.FaceColor = [0 0 1];
catch
end;
% Updating rectangle color
h.FaceColor = [1 0 0];
% Saving handle of the current rectangle
hAx.UserData = h;

% Updating title for the plot
title(hAx, sprintf('WT ID: %d, Damages: %d', wtID, size(tabDmg, 1)));

% Using a new function to plot damage locations in 3d
BDM_case1_vis_damage(wtID, tabDmg, blen, virt)

return;