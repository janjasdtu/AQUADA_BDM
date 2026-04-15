function BDM_case1_vis_damage(wtID, tabDmg, blen, virt)

% Function responsible for plotting localized blade damages on a model of a
% standardized wind turbine blade. Relies on the damages sheet imported
% during .xlsx importing. For example plotting the photo indexing is
% different due to placeholder images

% Damage sizes are not represented to scale!

fprintf('3D plotting is happening, dependent on damage amount \n')

% Loading in the pointclouds used for localization [cut loading from 25
% seconds to sub 1 second (can you tell im proud?)]
blade = virt.blade; lead = virt.lead; spar = virt.spar; trail = virt.trail;

% Check how many plots will have to be made, min 1 max 3
list = unique(tabDmg.BladeID);

% Splitting the blade up so damages can be properrly applied
front = {'LE suction','LE pressure','LE'};
mid = {'Suction side','Pressure side'};
back = {'TE suction','TE pressure', 'TE'};

% this is used to track the damage windows and close them
global figHandles
figHandles = [];

% Cycling through the blades
for j = 1:height(list)
    
    % Operating on a single blade
    filt = tabDmg.BladeID == list(j);
    small = tabDmg(filt,:);

    pchk = [0 0 0 0]; % Check if the clouds have been assigned

    small(:,"DaRSize") = small(:,"DaRSize") + 1; % Visibility of small damages
    
    % Plotting figure of the blades
    hFig = figure('Name', sprintf('3D Visualization of damage on turbine: %d and blade: %d', wtID, list(j)), ...
        'NumberTitle', 'off'); hold on;
    hFig.WindowState = 'maximized';
    
    % Values used to force pointCloud objects to show up on the blade.
    % Otherwise the gray 'blade' points would occlude the 'damage' points
    val1= 45;
    val2= 55;

    % Plotting blade
    pcshow(pointCloud(blade,"Color",[0.3 0.3 0.3]), 'MarkerSize', val1);
    
    % Its legend is empty
    leg{j} = {sprintf('Turbine: %d, Blade: %d', wtID, list(j)), 0.3, 0.3, 0.3, 'empty', 'empty', 'empty'};

    % Cycling through the damages
    for i = 1:height(small)
        
        % Typos in the database being adjusted
        if strcmp(small.CsPos(i),{'Spar suction'})
             small.CsPos(i) = cellstr('Suction side');
        end
        
        if strcmp(small.CsPos(i),{'Spar pressure'})
             small.CsPos(i) = cellstr('Pressure side');
        end 

        % Check damage location
        fc = strcmp(small.CsPos(i),front);
        mc = strcmp(small.CsPos(i),mid);
        bc = strcmp(small.CsPos(i),back);
        
        % Print failure assignment 
        if sum(fc) == sum([sum(mc) sum(bc)])
            fprintf(sprintf('Damage nr. %d called "%s" could not be assigned to a 3D plot', i, char(small.CsPos(i))));
            fprintf('\n')
            if strcmp(small.CsPos(i),'Undefined')
                fprintf('Damage called Undefined will be displayed as rings')
                fprintf('\n')
            end
        end 

        % Loop which takes 'Undefined' damages as rings, due to lack of
        % location
        if strcmp(small.CsPos(i),'Undefined')
            b_pos = interp1([0,blen],[min(lead(:,2)),max(lead(:,2))],small.RPos(i));
            lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];
            
            % Cut and combine blade elements
            cut_l = filter_func(lead,lims,2);
            cut_s = filter_func(spar,lims,2);
            cut_t = filter_func(trail,lims,2);
            
            cut = vertcat(cut_l,cut_s);
            cut = vertcat(cut,cut_t);

            col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

            if pchk(4) == 1
                udef_clouds = [udef_clouds; pointCloud(cut,"Color",col_4leg)];
            else
                pchk(4) = 1;
                % repository make
                udef_clouds = pointCloud(cut,"Color",col_4leg);
            end
            add = {append('Undefined, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
            
            leg{j} = vertcat(leg{j},add);
        end    

        % Based on the filtering, the damages are sorted to their
        % appropriate location

        if sum(fc) == 1
            if fc(1) == 1
                % Translate position on db blade into position on virt
                % blade
                b_pos = interp1([0,blen],[min(lead(:,2)),max(lead(:,2))],small.RPos(i));
                
                % Determine spanwise size
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                % Prevent damage from having no spanwise length
                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05; % otherwise these wont show up
                end

                % Making a section of the corresponding cloud
                % Uses internal function to filter the pointcloud
                cut = filter_func(lead,lims,2);
                cut = filter_func(cut,[min(cut(:,1))  max(cut(:,1)) - 0.2*max(cut(:,1))],1);
                cut = filter_func(cut,[0 max(cut(:,3))],3);

                % Random color assignment, kept constant for legend
                % attribution
                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                % Streamlined plotting process, adding clouds to the
                % repository
                if pchk(1) == 1
                    leading_clouds = [leading_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(1) = 1;
                    % Repository make
                    leading_clouds = pointCloud(cut,"Color",col_4leg);
                end
                
                % Adding to legend
                add = {append('LE suction side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);

            end

            % Until specified the filtering of front, middle and back sides
            % of the blade is done the same way

            if fc(2) == 1
                b_pos = interp1([0,blen],[min(lead(:,2)),max(lead(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05; % otherwise these wont show up
                end

                % Making a section of the corresponding cloud
                cut = filter_func(lead,lims,2);
                cut = filter_func(cut,[min(cut(:,1))  max(cut(:,1)) - 0.2*max(cut(:,1))],1);
                cut = filter_func(cut,[min(cut(:,3)) 0],3);
                
                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(1) == 1
                    leading_clouds = [leading_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(1) = 1;
                    leading_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('LE pressure side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);
            end

            if fc(3) == 1
                b_pos = interp1([0,blen],[min(lead(:,2)),max(lead(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                % Making a section of the corresponding cloud
                cut = filter_func(lead,lims,2);
                cut = filter_func(cut,[max(cut(:,1)) - 0.2*max(cut(:,1)) max(cut(:,1))],1);

                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(1) == 1
                    leading_clouds = [leading_clouds; pointCloud(cut,"Color",col_4leg)];
                
                else    
                    pchk(1) = 1;

                    leading_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('LE, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);
            end
        end

        % Middle part of the blade
        if sum(mc) == 1
            if mc(1) == 1
                b_pos = interp1([0,blen],[min(spar(:,2)),max(spar(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];
                
                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05; 
                end

                cut = filter_func(spar,lims,2);
                cut = filter_func(cut,[min(cut(:,1))  max(cut(:,1)) - 0.2*max(cut(:,1))],1);
                cut = filter_func(cut,[0 max(cut(:,3))],3);
                
                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(2) == 1
                    spar_clouds = [spar_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(2) = 1;
                    spar_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('Suction side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);
            end

            if mc(2) == 1 
                b_pos = interp1([0,blen],[min(spar(:,2)),max(spar(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05; 
                end

                cut = filter_func(spar,lims,2);
                cut = filter_func(cut,[min(cut(:,1))  max(cut(:,1)) - 0.2*max(cut(:,1))],1);
                cut = filter_func(cut,[min(cut(:,3)) 0],3);

                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(2) == 1
                    spar_clouds = [spar_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(2) = 1;
                    spar_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('Pressure side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);

            end
        end

        % Back side of the blade
        if sum(bc) == 1
            if bc(1) == 1
                b_pos = interp1([0,blen],[min(trail(:,2)),max(trail(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05; 
                end

                cut = filter_func(trail,lims,2);
                cut = filter_func(cut,[interp1([0 1],[min(cut(:,1)) max(cut(:,1))],0.3)  max(cut(:,1))],1);

                cut = filter_func(cut,[mean(cut(:,3))-0.3 max(cut(:,3))],3);

                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(3) == 1
                    trail_clouds = [trail_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(3) = 1;
                    trail_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('TE suction side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);
            end
            if bc(2) == 1
                b_pos = interp1([0,blen],[min(trail(:,2)),max(trail(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                if lims(1) == lims(2)
                    lims(1) = lims(1) - 0.05; lims(2) = lims(2) + 0.05;
                end

                cut = filter_func(trail,lims,2);

                cut = filter_func(cut,[interp1([0 1],[min(cut(:,1)) max(cut(:,1))],0.3)  max(cut(:,1))],1);
                cut = filter_func(cut,[min(cut(:,3)) mean(cut(:,3))-0.3],3);

                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(3) == 1
                    trail_clouds = [trail_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(3) = 1;
                    trail_clouds = pointCloud(cut,"Color",col_4leg);
                end
                add = {append('TE pressure side, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);

            end
            if bc(3) == 1
                b_pos = interp1([0,blen],[min(trail(:,2)),max(trail(:,2))],small.RPos(i));
                lims = [b_pos - small.DaRSize(i), b_pos + small.DaRSize(i)];

                cut = filter_func(trail,lims,2);
                cut = filter_func(cut,[min(cut(:,1)) interp1([0 1],[min(cut(:,1)) max(cut(:,1))],0.2)],1);
                
                col_4leg = generateDistinctColor(cell2mat(leg{j}(:,2:4)));

                if pchk(3) == 1
                    trail_clouds = [trail_clouds; pointCloud(cut,"Color",col_4leg)];
                else    
                    pchk(3) = 1;
                    trail_clouds = pointCloud(cut,"Color",col_4leg);
                end

                add = {append('TE, damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), sprintf('%d_%s_%02d', small.BladeID(i), small.InspDate{i}, small.No(i)), small.RPos(i), small.InspComm(i)};
                leg{j} = vertcat(leg{j},add);
            end
               
        end
        
    end


    % These checks prevent a situation where a blade didnt have any damage
    % in a region
    if exist('leading_clouds','var')
        pcshow(pccat(leading_clouds), 'MarkerSize',val2)
    end

    if exist('spar_clouds','var')
        pcshow(pccat(spar_clouds), 'MarkerSize',val2)
    end

    if exist('trail_clouds','var')
        pcshow(pccat(trail_clouds), 'MarkerSize',val2)
    end

    if exist('udef_clouds','var')
        pcshow(pccat(udef_clouds), 'MarkerSize',val2)
    end
    
    % Otherwise they end up overlapping
    clear leading_clouds spar_clouds trail_clouds udef_clouds

    % Making the plot pretier by choosing a specific view angle
    axis off
    view(45,30)
    set(hFig, 'Color', [1 1 1]);
    % Set up the position for the overall box
    boxPosition = [0.05, 0.05, 0.10, 0.03*height(leg{j})]; % [x, y, width, height]

    % Add the overall background box
    bRec = annotation('rectangle', boxPosition, 'FaceColor', 'white', 'EdgeColor', 'black');

    % Loop through each label and add annotations within the box
    for i = 1:height(leg{j})
        % Determine position for each text box relative to the overall box
        xPos = boxPosition(1) + 0.02;
        yPos_t = boxPosition(2) + boxPosition(4) - ((i+1) * 0.028);
        yPos_b = boxPosition(2) + boxPosition(4) - ((i) * 0.028);
        
        % Initial value of font size used to write the blade description
        if i == 1
            fontSize = 14;
        end

        % Add text box annotation with white background
        hRec2 = annotation('textbox', [xPos yPos_t 0.18 0.05], 'String', leg{j}{i,1}, 'FitBoxToText', 'on', 'EdgeColor', 'White', 'FontSize', fontSize);
        
        % Check to see if the text box fits inside the bg box, it never
        % does so the fontsize is adjusted
        if i == 1
            fontSize = checkTextFit(hRec2, leg{j}{i,1});
            set(hRec2, 'FontSize', fontSize); % then I force it (asked for it)
        end

        % Add colored box annotation next to text
        hRec = annotation('rectangle', [xPos-0.019 yPos_b+0.004 0.015 0.015], 'FaceColor', cell2mat(leg{j}(i,2:4)), 'EdgeColor', 'none');

        % Call interaction objects (with the photo folder adress accessed
        % through ploc
        set(hRec, 'ButtonDownFcn', {@BDM_case1_vis_dclick, leg{j}(i,5), leg{j}(i,6), leg{j}(i,7)});
        set(hRec2, 'ButtonDownFcn', {@BDM_case1_vis_dclick, leg{j}(i,5), leg{j}(i,6), leg{j}(i,7)});
    end

end

end


%% Internal repository of functions

% Simple filtering function for pointClouds
function output = filter_func(data,lim,cdir)
    
    output = data(data(:,cdir)>=lim(1) & data(:,cdir)<=lim(2), :);

end

% Correct color coding functionality
function newColor = generateDistinctColor(previousColors)
    % Threshold for sufficient difference
    minDistance = 0.25;
    
    while true
        % Generate a new candidate color
        newColor = rand(1, 3);
        
        % Check if the new color is sufficiently different from previous colors
        isDistinct = true;
        for i = 1:size(previousColors, 1)
            distance = norm(newColor - previousColors(i, :));
            if distance < minDistance
                isDistinct = false;
                break;
            end
        end
        
        % Break the loop if a distinct color is found
        if isDistinct
            break;
        end
    end
end

% Checker of Legend font size to adjust to screen size, otherwise out of
% bounds
function fontSize = checkTextFit(textHandle, textString)
    % Define a lookup table for screen resolutions and corresponding font sizes
    lookupTable = {
        [1920, 1080], 7;  % Full HD
        [1366, 768], 5;   % HD
        [1280, 720], 5;    % HD
        [1600, 900], 6;   % HD+
        [2560, 1440], 9;  % QHD
        [3840, 2160], 14;  % 4K UHD
    };
    
    % Convert the lookup table to arrays for interpolation
    resolutions = cell2mat(lookupTable(:, 1));
    fontSizes = cell2mat(lookupTable(:, 2));
    
    % Get the screen size
    screenSize = get(0, 'ScreenSize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);
    
    % Calculate the resolution as a single value for interpolation
    screenResolution = sqrt(screenWidth^2 + screenHeight^2);
    lookupResolutions = sqrt(sum(resolutions.^2, 2));
    
    % Interpolate the font size based on the screen resolution
    fontSize = interp1(lookupResolutions, fontSizes, screenResolution, 'linear', 'extrap');
    
    % Set the text string and font size
    set(textHandle, 'String', textString, 'FontSize', round(fontSize));
end


