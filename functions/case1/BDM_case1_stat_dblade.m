function BDM_case1_stat_dblade(~,~,bdDB, savePlot, dmgCat, dmgCatInst, spanRange, spanRes)

% Plotting span-wise distribution of blade damages, based on the chosen
% damage type from the dropdown

%% Substitutions
tabDmgMap = bdDB.damages;
daRPos    = tabDmgMap.RPos;
daRSize   = tabDmgMap.DaRSize;
dSize     = tabDmgMap.Size;
ori       = tabDmgMap.Ori;

%% Processing

% Bins for histogram
binEdges = spanRange(1):spanRes:spanRange(2);
% Number of bins
binNum = length(binEdges)-1;

% Check that category is in the table
if ~sum(strncmp(tabDmgMap.Properties.VariableNames, dmgCat, length(dmgCat)))
  warning('Unknown damage category!');
end

% List of present category instances
catInstListAll = unique( tabDmgMap.(dmgCat) );
% Filtering the category instances
catInstList = cell(0);
if ~strcmp(dmgCatInst(1), 'All')
  for dmgCatInstNo = 1:length(dmgCatInst)
    cDmgCatInst = dmgCatInst{dmgCatInstNo};
    if sum(strncmp(catInstListAll, cDmgCatInst, length(cDmgCatInst)))
      catInstList = [catInstList; cDmgCatInst];
    end;
  end;
else
  catInstList = catInstListAll;
end;
% Number of category instances
catInstNum = length(catInstList);

% Categorized number of damages per range
dmgNum = zeros(catInstNum, binNum);
% Categorized damage table
tabDmg = cell(catInstNum, binNum);

% Filtering and categorization
for binNo = 1:binNum
  % Current bin edges
  binEl = binEdges(binNo);
  binEr = binEdges(binNo+1);
  % Single damages falling into the bin
  dmgSNos = ~daRSize & ~( (daRPos-dSize./2.*cosd(ori) >= binEr) | (daRPos+dSize./2.*cosd(ori) < binEl) );
  % Damage areas falling into the bin
  dmgANos = daRSize & ~( (daRPos-daRSize./2 >= binEr) | (daRPos+daRSize./2 <= binEl) );
  
  % Table of all blade damages in the bin range
  tabDmgRange = tabDmgMap(dmgSNos|dmgANos,:);
  
  % Filtering the damages
  for catInstNo = 1:catInstNum
    % Category instance name
    catInst = catInstList(catInstNo);
    % Filtered damages
    tabDmg{catInstNo, binNo} = tabDmgRange( strcmp(tabDmgRange.(dmgCat),catInst), :);
    % Number of filtered damages
    dmgNum(catInstNo, binNo) = height(tabDmg{catInstNo, binNo});
   end;
end;

%% Plotting
% Figure format
hFig = figure('Name', sprintf('%s. Blade span-wise damage distribution', bdDB.parkname), 'NumberTitle', 'off'); hold on;
hFig.Position = [444 170 650 420];
hAx = gca();
hAx.FontSize = 14;
xlabel('Blade length, m');
ylabel('Number of damages');
xlim(spanRange);

%T he bars
bars = bar( (binEdges(1:end-1)+binEdges(2:end))/2, dmgNum.', 'stacked');
% The legend
legend(catInstList, 'Location', 'northwest');

%% Handler functions, legacy code
for catInstNo = 1:catInstNum
    set(bars(catInstNo), 'ButtonDownFcn', {@BDM_case1_stat_bclick, tabDmg(catInstNo,:), binEdges});
end;

%% Saving the plot, legacy code
if savePlot > 0
  print(hFig, fullfile('figures', sprintf('%s - Blade span-wise damage distribution', bdDB.parkName)), '-dmeta');
end;
return;