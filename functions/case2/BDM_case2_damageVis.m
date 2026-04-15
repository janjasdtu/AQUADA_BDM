function BDM_case2_damageVis(blade,meta)

    % Function used to visualize damages on a singular blade, based on the
    % location input through the ingestion of 'Case 2'. 

    % Functionality very similar to 'BDM_case1_vis_damage', exept for the
    % usage of damag locations


    % Values used to force pointCloud objects to show up on the blade.
    % Otherwise the gray 'blade' points would occlude the 'damage' points
    val1= 45;
    val2= 55;
    
    global figHandles
    figHandles = [];
    
    % Main loop for placing the damages in correct locations
    
    hFig = figure('Name', ['Damage visualization for project: ', meta.Project_Name], 'NumberTitle', 'off'); hold on;
    hFig.WindowState = 'maximized';
    
    pcshow(pointCloud(blade,"Color",[0.3 0.3 0.3]), 'MarkerSize', val1)
    leg = {'Overview for blade', 0.3, 0.3, 0.3, 'empty'};

    sizer = 1; % Size of the visualized damage on the blade
    cld = [];
    
    % Locating damages on the blade
    for i = 1:meta.Subfolder_num
    
        coords = meta.(['Damage_',num2str(i)]).Coords;
    
        lims_y = [coords(1) - sizer, coords(1) + sizer];
        lims_x = [coords(2) - sizer, coords(2) + sizer];
        cut = filter_func(blade,lims_x,1);
        cut = filter_func(cut,lims_y,2);
        if coords(1,3,1) == 2
            lims_z = [mean(cut(:,3)) max(cut(:,3))];
            cut = filter_func(cut,lims_z,3);
        else
            lims_z = [min(cut(:,3)) mean(cut(:,3))];
            cut = filter_func(cut,lims_z,3);
        end
        col_4leg = generateDistinctColor(cell2mat(leg(:,2:4)));
        cut = pointCloud(cut,"Color",col_4leg);
    
        add = {append('Tracked damage ',num2str(i)), col_4leg(1), col_4leg(2), col_4leg(3), 'hold'};
        leg = vertcat(leg,add);
        cld = [cld; cut];
    
    end    
    
    pcshow(pccat(cld), 'MarkerSize',val2)
    axis off
    view(45,30)
    set(hFig, 'Color', [1 1 1]);
    % Set up the position for the overall box
    boxPosition = [0.05, 0.05, 0.10, 0.03*height(leg)]; % [x, y, width, height]
    
    % Add the overall background box
    bRec = annotation('rectangle', boxPosition, 'FaceColor', 'white', 'EdgeColor', 'black');
    
    % Loop through each label and add annotations within the box
    for i = 1:height(leg)
        % Determine position for each text box relative to the overall box
        xPos = boxPosition(1) + 0.02;
        yPos_t = boxPosition(2) + boxPosition(4) - ((i+1) * 0.028);
        yPos_b = boxPosition(2) + boxPosition(4) - ((i) * 0.028);
    
        % Initial value of font size used to write the blade description
        if i == 1
            fontSize = 14;
        end
    
        % Add text box annotation with white background
        hRec2 = annotation('textbox', [xPos yPos_t 0.18 0.05], 'String', leg{i,1}, 'FitBoxToText', 'on', 'EdgeColor', 'none', 'FontSize', fontSize);
    
        % check to see if the text box fits inside the bg box, it never
        % does so the fontsize is adjusted
        if i == 1
            fontSize = checkTextFit(hRec2, leg{i,1});
            set(hRec2, 'FontSize', fontSize); % then I force it (asked for it)
        end
    
        % Add colored box annotation next to text
        hRec = annotation('rectangle', [xPos-0.019 yPos_b+0.004 0.015 0.015], 'FaceColor', cell2mat(leg(i,2:4)), 'EdgeColor', 'none');
    
        % call interaction objects
        if i == 1
            set(hRec, 'ButtonDownFcn', {@BDM_case2_DmgLocClick, meta.(['Damage_',num2str(i)]).Address,true});
        else
            set(hRec, 'ButtonDownFcn', {@BDM_case2_DmgLocClick, meta.(['Damage_',num2str(i-1)]).Address,false});
        end
    end
    
    end
    
% Filter func to visualize
function output = filter_func(data,lim,cdir)
    
    output = data(data(:,cdir)>=lim(1) & data(:,cdir)<=lim(2), :);

end

% Function to assign specific color
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
        [1600, 900], 7;   % HD+
        [2560, 1440], 9;  % QHD
        [3840, 2160], 18;  % 4K UHD
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

