function BDM_case2_make

% Function used when a singuar blade is ingested, requiring cycling through
% folders containing the images of blade damage and specifying where those
% damages are found on the blade

fprintf('Case 2 ingest has begun. Follow window prompts; look to cmd window for feedback \n')

% Loading required information
virt = importdata('virtual.asc',';');
blade(:,:) = virt(:,1:3);
clear virt % Cleaning memory
shape_2d = importdata('dam_loc_mat.asc',';');

% Get the project name
projectName = getProjectName();

% Select the project folder
projectFolder = selectProjectFolder();

% Updating the BDM database
updateDatabase(projectName, projectFolder)

disp('Database updated with new C2 entry.')

% Now use that information in order to cycle through damage folders and
% assign locations
if isempty(projectFolder)
    disp('No valid folder selected.');
else
    % Get the list of subfolders
    subfolders = dir(projectFolder);
    subfolders = subfolders([subfolders.isdir] & ~ismember({subfolders.name}, {'.', '..'}));
    
    % Print the number of subfolders to the console
    numSubfolders = numel(subfolders);
    fprintf('Number of damage subfolders: %d\n', numSubfolders);
    
    meta.Project_Name = projectName; meta.Project_Folder = projectFolder;
    meta.Subfolder_num = numSubfolders;

    % Loop over each subfolder
    for i = 1:numSubfolders

        subfolderPath = fullfile(projectFolder, subfolders(i).name);
        
        % Create the new sub-struct
        newSStruct.Address = subfolderPath;
        
        % Get the list of image files in the subfolder
        imageFiles = dir(fullfile(subfolderPath, '*.png'));
        imageFiles = [imageFiles; dir(fullfile(subfolderPath, '*.jpg'))];
        imageFiles = [imageFiles; dir(fullfile(subfolderPath, '*.jpeg'))];
        
        % Sort image files by date using filenames
        baseFilenames = cellfun(@(x) x(1:end-4), {imageFiles.name}, 'UniformOutput', false);
        imageDates = datetime(baseFilenames, 'InputFormat', 'yyyyMMdd_HHmmss');
        [~, idx] = sort(imageDates);
        imageFiles = imageFiles(idx);
        
        if ~isempty(imageFiles)
            % Get the first and last image
            firstImage = fullfile(subfolderPath, imageFiles(1).name);
            lastImage = fullfile(subfolderPath, imageFiles(end).name);
  
            mode = promptUserMode(); % Prompting suction or pressure side for damages
            
            coords = damagePointsLocator(projectName,i,mode,shape_2d,firstImage,lastImage);
            
            % Add the new sub-struct to the database
            newSStruct.Coords = coords;
            meta.(['Damage_', num2str(i)]) = newSStruct;
            
            disp(['Damage for images in folder: ', num2str(i),' have been marked'])
        else
            fprintf('No valid images found in subfolder: %s\n', subfolders(i).name);
        end
    end

 
    % Save the struct to the specified folder
    save(fullfile(projectFolder, 'meta.mat'), 'meta');

    disp('Now visualizing the blade')
    BDM_case2_damageVis(blade,meta)

end

%% Function repository

% Get project name
function projectName = getProjectName()
    % Create a figure window for project name input
    hFig = figure('Name', 'Create Project', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.3, 0.3, 0.4, 0.3]);
    
    % Create a text field and OK button
    uicontrol('Style', 'text', 'String', 'Enter Project Name:', 'Units', 'normalized', 'Position', [0.1, 0.7, 0.8, 0.15], 'FontSize', 12);
    hNameField = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [0.1, 0.5, 0.8, 0.15], 'FontSize', 12);
    uicontrol('Style', 'pushbutton', 'String', 'OK', 'Units', 'normalized', 'Position', [0.4, 0.2, 0.2, 0.15], 'FontSize', 12, 'Callback', @okButtonCallback);
    
    % Wait for the user to input the project name
    uiwait(hFig);
    
    function okButtonCallback(~, ~)
        % Get the project name from the text field
        projectName = get(hNameField, 'String');
        
        % Resume execution before closing the figure
        uiresume(hFig);
        
        % Close the input window
        close(hFig);
    end
end

% Select project folder
function projectFolderRel = selectProjectFolder()
    % Open a folder selection dialog
    selectedFolder = uigetdir('', 'Select Project Folder');
    
    if selectedFolder == 0
        disp('No folder selected.');
        projectFolderRel = '';
        return;
    end

    % Normalize slashes
    selectedFolder = strrep(selectedFolder, '\', '/');

    % Define the anchor folder name
    anchor = 'BDM_software';

    % Find the position of the anchor
    idx = strfind(selectedFolder, anchor);

    if isempty(idx)
        error('Selected folder is not inside the BDM_papercode project.');
    end

    % Extract the relative path after the anchor
    anchorEnd = idx + length(anchor);
    projectFolderRel = strtrim(selectedFolder(anchorEnd+1:end));  % skip slash
end



% Update the database file
    function updateDatabase(projectName, projectFolderRel)
    % Load the existing database
    load('database.mat', 'database');

    % Get the current number of Available_BDM
    currentBDM = database.Available_BDM;

    % Increment the Available_BDM count
    newBDM = currentBDM + 1;
    database.Available_BDM = newBDM;

    % Create the new sub-struct
    newSubStruct.Name = projectName;
    newSubStruct.Address = projectFolderRel;  % Store relative path
    newSubStruct.Case = 2;

    % Add the new sub-struct to the database
    database.(['BDM_0', num2str(newBDM)]) = newSubStruct;

    % Save the updated database back to the file
    save('database.mat', 'database');
end



%% Functionality for locating damages

% Decide if the damage is on the pressure or suction side
function mode = promptUserMode()

    screenSize = get(0, 'ScreenSize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);

    windowWidth = 250;
    windowHeight = 100;

    % Calculate the position to center the window
    windowX = (screenWidth - windowWidth) / 2;
    windowY = (screenHeight - windowHeight) / 2;

    % Create the initial dialog box with two buttons
    d = dialog('Position', [windowX, windowY, 400, 120], 'Name', 'Select view direction');
    
    % Initialize the mode variable
    mode = '';
    
    uicontrol('Parent', d, ...
              'Style', 'pushbutton', ...
              'Position', [25, 70, 350, 40], ...
              'String', 'Pressure', ...
              'Callback', @(src, event) selectMode(d, 'Pressure'));
          
    uicontrol('Parent', d, ...
              'Style', 'pushbutton', ...
              'Position', [25, 20, 350, 40], ...
              'String', 'Suction', ...
              'Callback', @(src, event) selectMode(d, 'Suction'));

    % Wait for the user to select a mode
    uiwait(d);
    
    function selectMode(dialog, selectedMode)
        % Set the selected mode
        mode = selectedMode;
        
        % Close the dialog box
        delete(dialog);
    end
end

% Function responsible for visualizing a 2d blade which is used to pinpoint
% locaitons
function clickedPointsArray = damagePointsLocator(projectName, i, mode, points, img1, img2)
    
    % Drawing shape from blatabase repository
    shapeX = points(:,1);
    shapeY = points(:,2);
    
    % Create the figure and make it fullscreen
    figureHandle = figure('Name',['Entering damage locations for project: ', projectName,', damage subfolder: ',num2str(i)],'WindowState', 'maximized', 'NumberTitle', 'off');
    
    % Create a panel for the images
    imgPanel = uipanel('Parent', figureHandle, 'Position', [0 0.5 1 0.5]);
    
    % Display the images side by side
    ax1 = subplot(1, 2, 1, 'Parent', imgPanel);
    hold on
    imshow(img1, 'Parent', ax1);
    title('Displaying first image from folder')
    axis(ax1, 'image'); % Ensure the image scales properly
    hold off

    ax2 = subplot(1, 2, 2, 'Parent', imgPanel);
    hold on
    imshow(img2, 'Parent', ax2);
    title('Displaying last image from folder')
    axis(ax2, 'image'); % Ensure the image scales properly

    % Create a panel for the interactable shape
    shapePanel = uipanel('Parent', figureHandle, 'Position', [0 0 1 0.5]);
    
    % Plot the shape in the shape panel
    axes('Parent', shapePanel);
    hold on;
    if strcmp(mode,'Suction')
        title('Click blade to specify coordinates -- Suction Side --');
        fill(-shapeX, shapeY, 'g', 'FaceAlpha', 0.3);
    elseif strcmp(mode,'Pressure')
        title('Click blade to specify coordinates -- Pressure Side --');
        fill(-shapeX, -shapeY, 'g', 'FaceAlpha', 0.3);
    end
    axis equal;
    
    % Set the axes limits
    xlabel('Blade span');
    ylabel('Blade chord');
    axis off;
    
    % Initialize the clicked points as an empty array
    global clickedPoints;
    clickedPoints = [];
    
    % Store the clicked points array in the figure's guidata
    guidata(figureHandle, clickedPoints);

    % Set the callback function for mouse clicks
    if strcmp(mode,'Suction')
        set(figureHandle, 'WindowButtonDownFcn', @(src, event) mouseClickCallback(src, event, -shapeX, shapeY, mode));
    elseif strcmp(mode,'Pressure')
        set(figureHandle, 'WindowButtonDownFcn', @(src, event) mouseClickCallback(src, event, -shapeX, -shapeY, mode));
    end
    

    % Set the callback function for closing the figure window
    set(figureHandle, 'CloseRequestFcn', @(src, event) closeFigureCallback(src, event));
    
    % Wait for the figure to close
    uiwait(figureHandle);
    
    % Retrieve the clicked points from guidata
    clickedPointsArray = clickedPoints;
end

% Callback Function for Mouse Click:
function mouseClickCallback(~, ~, shapeX, shapeY, mode)
    global clickedPoints;

    % Check for right mouse click to terminate the figure
    if strcmp(get(gcf, 'SelectionType'), 'alt')
        close(gcf);
        return;
    end

    % Get the current point of the click
    clickPoint = get(gca, 'CurrentPoint');
    xClick = clickPoint(1, 1);
    yClick = clickPoint(1, 2);
    
    % Check if the click is inside the shape
    isInside = inpolygon(xClick, yClick, shapeX, shapeY);
    
    % Retrieve the current clicked points from guidata
    fig = gcf;
    clickedPoints = guidata(fig);
    
    if isInside
        %fprintf('Clicked inside shape at: Y = %.2f, X = %.2f\n', xClick, yClick);
        % Add the clicked point to the list
        if strcmp(mode,'Suction')
            clickedPoints(end+1, :) = [-xClick, -yClick, 1];
        elseif strcmp(mode,'Pressure')
            clickedPoints(end+1, :) = [-xClick, yClick, 2];
        end
        
        % Plot the red 'x' at the clicked location
        plot(xClick, yClick, 'rx', 'LineWidth', 2, 'MarkerSize', 10);
    else
        fprintf('Area around the blade was clicked (you missed) \n');
    end

    % Save the updated clicked points in guidata
    guidata(fig, clickedPoints);
    
    
end

% Callback Function for Closing the Figure:
function closeFigureCallback(src, ~)
    global clickedPoints;

    % Retrieve the clicked points from guidata
    clickedPointsArray = guidata(src);
    
    % Print the clicked points array
    clickedPoints = clickedPointsArray;
    % Resume the main function
    uiresume(src);

    % Close the figure window
    delete(src);
end


end