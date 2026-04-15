function BDM_case1_stat_park(bdDB, savePlot)

% Plotting the park layout, based on the inputs in the turbines tab during
% ingestion of the .xlsx sheet. Assuming XY coordinates are known

%% Pre-processing
tabWtLayout = bdDB.turbines;

%% Calculations
% WT grid dimensions
spanX = max(tabWtLayout.CoordX) - min(tabWtLayout.CoordX);
spanY = max(tabWtLayout.CoordY) - min(tabWtLayout.CoordY);
% Plotting margin
margin = 0.1.*min([spanX spanY]);

%% Plotting
% Figure
hFig = figure('Name', sprintf('%s. Wind farm layout', bdDB.parkname), 'NumberTitle', 'off');
hold on; grid on; axis equal;
hFig.Position = [444 170 650 420];
% Axes limits
xlim( [min(tabWtLayout.CoordX)-margin max(tabWtLayout.CoordX)+margin] );
ylim( [min(tabWtLayout.CoordY)-margin max(tabWtLayout.CoordY)+margin] );
% Plotting
plot(tabWtLayout.CoordX,  tabWtLayout.CoordY,  'rx', 'LineWidth', 2);

%% Saving the plot
if savePlot > 0
  print(hFig, fullfile('figures', sprintf('%s - Layout', bdDB.parkname)), '-dmeta');
end;
return;

