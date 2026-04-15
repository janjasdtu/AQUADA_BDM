function BDM_case1_stat_dpark(~,~, bdDB, savePlot, dmgCat, dmgCatInst)

% Plotting damage map. Number of damages per WT is plotted as a blue circle
% with the radius proportional to the number of damages found om this WT. If
% no damages are found on this WT, the circle is of monimum size and white.
% If the WT was not inspected, the circle is of minimum size and is yellow.

%% Substitutions
tabDmgMap   = bdDB.damages;   % Blade damage map, table
tabBladeMap = bdDB.blades;    % Blade map, table
tabWtLayout = bdDB.turbines;  % WT map, table

%% Data processing
% Number of wind turbines
wtNum = height(tabWtLayout);

% Damages grouped by WT
tabDmg   = cell(wtNum,1);    % Table of filtered damages
wtDmg    = zeros(wtNum, 1);  % Number of filtered damage per WT
wtDmgAll = zeros(wtNum, 1);  % Number of damages per WT

% Damage filtering by WT
for wtNo = 1:height(tabWtLayout)
  % Current turbine ID
  wtgID = tabWtLayout.WTGID(wtNo);
  % Blades of the current turbine
  bladeIDs = tabBladeMap.BladeID( tabBladeMap.WTGID == wtgID );
  
  % Skipping WT without registered damages
  if isempty(bladeIDs)
    continue;
  end;
  
  % Index table of all blade damages of the WT
  iDmgAll = logical(sum(repmat(tabDmgMap.BladeID, 1, length(bladeIDs)) == repmat(bladeIDs.', size(tabDmgMap.BladeID,1), 1), 2));
  % Table of all blade damages in the WT
  dmgWT = tabDmgMap(iDmgAll,:);
  
  % No-filtering (All damages shown)
  if strcmp(dmgCat, 'all')
    % Damages for the blade
    tabDmg{wtNo} = [tabDmg{wtNo}; dmgWT];
  % Damage filtering
  else
    % Indeces of filtered damage of the category
    indDmgCat = true(height(dmgWT),1);
    % Each damage category one by one
    for catNo = 1:length(dmgCat)
      % Damage category name
      catName = dmgCat{catNo};
      % Check that category is in the table
      if ~sum(strncmp(dmgWT.Properties.VariableNames, catName, length(catName)))
        warning('Unknown damage category!');
        continue;
      end
      
      % Indeces of filtered damage of the category instances
      indDmgCatInst = false(height(dmgWT),1);
      % Each damage category instance one by one
      for catInstNo = 1:length(dmgCatInst{catNo})
        % Damage category instance name
        catInstName = dmgCatInst{catNo}{catInstNo};
        % Ideces of damages of the category instance
        indDmgCatInst = indDmgCatInst | strncmp(dmgWT{:,catName}, catInstName, length(catInstName));
      end;

      % Logical AND between the damage categories
      indDmgCat = indDmgCat & indDmgCatInst;
    end;

    % Filtered damages per WT
    tabDmg{wtNo} = dmgWT(indDmgCat,:);
  end;
  
  % Number of filtered damages per WT
  wtDmg(wtNo) = size(tabDmg{wtNo}, 1);
  % Number of all damages per WT
  wtDmgAll(wtNo) = size(dmgWT, 1);
end;

%% Plotting parameters
% WT grid dimensions
spanX = max(tabWtLayout.CoordX) - min(tabWtLayout.CoordX);
spanY = max(tabWtLayout.CoordY) - min(tabWtLayout.CoordY);
% Plotting margin
margin = 0.1.*min([spanX spanY]);
% Minimun distance between the WT in the park
WTGrid = [tabWtLayout.CoordX tabWtLayout.CoordY];
WTDist = pdist2(WTGrid, WTGrid);
WTDist = triu(WTDist);
WTDistMin = min(WTDist(WTDist>0));
% Maximum number of damages per WT
WTDmgMax = max(wtDmgAll);
% Damage circle radius ratio
dmg2R = 0.9.*(0.45.*WTDistMin) ./ WTDmgMax;
% Damage circle radius additive
dDmgR = 0.2.*(0.45.*WTDistMin);
% Damage category description
if strcmp(dmgCat, 'all')
  sTitle = sprintf('\\bf{All damages}');
else
  sTitle = '';
  % Adding each damage category
  for catNo = 1:length(dmgCat)
    sTitle = sprintf('%s\\bf{%s}:', sTitle, dmgCat{catNo});
    % Adding each damage category instance
    for catInstNo = 1:length(dmgCatInst{catNo})
      sTitle = sprintf('%s \\rm{%s}', sTitle, dmgCatInst{catNo}{catInstNo});
      % Comma after each category instances
      if catInstNo ~= length(dmgCatInst{catNo})
        sTitle = sprintf('%s,', sTitle);
      end;
    end;
    % Semicolon after each damage category or dot in the end
    if catNo ~= length(dmgCat)
      sTitle = sprintf('%s; ', sTitle);
    else
      sTitle = sprintf('%s.', sTitle);
    end;
  end;
end;


%% Plotting
hFig = figure('Name', sprintf('%s. Damage map', bdDB.parkname), 'NumberTitle', 'off'); hold on; axis equal;
hFig.Position = [444 170 650 420];
hAx = gca();
hAx.XTick = [];
hAx.YTick = [];
hAx.XColor = [1, 1, 1];
hAx.YColor = [1, 1, 1];
% Axes limits
xlim( [min(tabWtLayout.CoordX)-margin max(tabWtLayout.CoordX)+margin] );
ylim( [min(tabWtLayout.CoordY)-margin max(tabWtLayout.CoordY)+margin] );
% Damage category description
xlabel(sprintf('\\color{black}%s', sTitle));

% Plotting WT damage circles one by one
for wtNo = 1:height(tabWtLayout)
  % Damage circle radius
  R = wtDmg(wtNo).*dmg2R + dDmgR;
  % WT position
  X0 = tabWtLayout.CoordX(wtNo);
  Y0 = tabWtLayout.CoordY(wtNo);
  % Plotting the damage circle
  if wtDmg(wtNo)
    % Blue damage circle
    hRec = rectangle('Position', [X0-R Y0-R, 2*R, 2*R], 'Curvature',1, 'FaceColor', 'Blue', 'EdgeColor', 'Black');
    set(hRec, 'ButtonDownFcn', {@BDM_case1_stat_wclick, hAx, tabWtLayout.WTGID(wtNo), tabDmg{wtNo}});
  elseif wtDmgAll(wtNo)
    % Circle is white
    rectangle('Position', [X0-R Y0-R, 2*R, 2*R], 'Curvature',1, 'FaceColor', 'White', 'EdgeColor', 'Black');
  else
    % Circle is yellow
    rectangle('Position', [X0-R Y0-R, 2*R, 2*R], 'Curvature',1, 'FaceColor', 'Yellow', 'EdgeColor', 'Black');
  end;
end;



%% Saving the plot, legacy
if savePlot > 0
  print(hFig, fullfile('figures', sprintf('%s - Damage map', bdDB.parkName)), '-dmeta');
end;
return;