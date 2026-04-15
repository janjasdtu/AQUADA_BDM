function BDM_case1_stat_wclick(h, ~, hAx, wtID, tabDmg)

% Interaction with the WT in the park plot, 'clicking' a turbine is set to
% reference the data of that turbine and displaying it in a new window

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

% Damage photo list
phList = cell(1);
for dmgNo = 1:height(tabDmg)
    phList{dmgNo} = sprintf('%d_%s_%02d', tabDmg.BladeID(dmgNo), tabDmg.InspDate{dmgNo}, tabDmg.No(dmgNo));
end;

% Damage Viewer
hView = bdmDmgViewer();

% Damage photo figure initialization
hPhotoAx = hView.Children(2);
hPhotoAx.Visible = 'Off';

% Damage list initialization
hDmgList = hView.Children(1);
hDmgList.String = phList;
hDmgList.Callback = {@BDM_case1_stat_dclick, hView, hPhotoAx, tabDmg};

% Show initial photo
hDmgList.Value = 1;
BDM_case1_stat_dclick(hDmgList, 0, hView, hPhotoAx, tabDmg);

return;