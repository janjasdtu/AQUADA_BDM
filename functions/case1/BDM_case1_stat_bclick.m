function BDM_case1_stat_bclick(~, eventData, tabDmg, binEdges)

% Function for showing the images related to the statistics bar that was
% interacted with through the display of damages or their severity

%Clicked bar
xPos = eventData.IntersectionPoint(1);
if nargin == 4
  barNo = sum(xPos>binEdges);
else
  barNo = round(xPos);
end;
%Filtered damage list
tabDmgList = tabDmg{barNo};

%Damage photo list
phList = cell(1);
for dmgNo = 1:height(tabDmgList)
    phList{dmgNo} = sprintf('%d_%s_%02d', tabDmgList.BladeID(dmgNo), tabDmgList.InspDate{dmgNo}, tabDmgList.PhotoNo(dmgNo));
end

%Damage Viewer
hView = bdmDmgViewer();

%Damage photo figure initialization
hPhotoAx = hView.Children(2);
hPhotoAx.Visible = 'Off';

%Damage list initialization
hDmgList = hView.Children(1);
hDmgList.String = phList;
hDmgList.Callback = {@BDM_case1_stat_dclick, hView, hPhotoAx, tabDmgList};

%Show initial photo
hDmgList.Value = 1;
BDM_case1_stat_dclick(hDmgList, 0, hView, hPhotoAx, tabDmgList);
return;