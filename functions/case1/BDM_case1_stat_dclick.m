function BDM_case1_stat_dclick(hObject, ~, hView, hAx, tabDmgList)

% Updating the damage photo on mouse click on the damage list

global ploc

% Damage info
tabDmg = tabDmgList(hObject.Value,:);
% Photo name (partial file path)
photoStr = sprintf('%d_%s_%02d', tabDmg.BladeID(1), tabDmg.InspDate{1}, tabDmg.PhotoNo(1));
% Full path to photo file
fPathPhoto = fullfile(ploc, sprintf('%s.jpg', photoStr) );
% Show the photo
imshow(fPathPhoto, 'InitialMagnification', 'fit', 'Parent', hAx);
% Damage position range
if tabDmg.DaRSize(1) == 0
  sRPosRange = sprintf('[%.2f-%.2f]', tabDmg.RPos(1)-tabDmg.Size(1)/2*cosd(tabDmg.Ori(1)), tabDmg.RPos(1)+tabDmg.Size(1)/2*cosd(tabDmg.Ori(1)));
else
  sRPosRange = sprintf('[%.2f-%.2f]', tabDmg.RPos(1)-tabDmg.DaRSize(1)/2, tabDmg.RPos(1)+tabDmg.DaRSize(1)/2);
end;
% Damage info into the window name
hView.Name = sprintf('Blade #%d, Rpos = %s at %s. Type: %s (%s). Comm: %s/%s',...
                      tabDmg.BladeID(1),...
                      sRPosRange,...
                      tabDmg.CsPos{1},...
                      upper(tabDmg.Type{1}),...
                      tabDmg.Depth{1},...
                      tabDmg.InspComm{1},...
                      tabDmg.AnlComm{1});
end