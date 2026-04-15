
% Welcome to the 2026 AQUADA BDM software.

% If you have just unpacked the software, you can perform a test RUN
% all the paths are relative meaning you will be able to access the example
% datasets without issues


% For more details regarding software functionality, refer to paper:
% AQUADA BDM - A modular software framework for centralized management 
% and 3D visualization of wind turbine blade damage inspection data

%%

% Clearning and running fresh

clc
close all
clear all


%% Run BDM

addpath functions
addpath functions/case1 % all functions for case 1, make store and review data
addpath functions/case2 % all functions for case 2, make store and review data
addpath functions/util % utilities related to loading blade information

main_window % main run of the software

%% Functionality refering to the main window buttons and all interactions

function main_window

    % Create main figure window in fullscreen
    hMainFig = figure('Name', 'Blade Damage Map: Main Window', 'NumberTitle', 'off');
    hMainFig.WindowState = 'maximized';
    
    % Display image in the middle
    img = imread('BDM_splash.jpg');
    imgAx = axes('Parent', hMainFig, 'Position', [0.05, 0.25, 0.6, 0.65]); % Adjusted height to make room for console
    imshow(img, 'Parent', imgAx);
    
    % Get the position of the image axis
    imgPos = get(imgAx, 'Position');
    
    % Calculate the position for the buttons relative to the image
    buttonWidth = 0.25;
    buttonHeight = 0.15;
    buttonX = imgPos(1) + imgPos(3) + 0.05; % 5% to the right of the image
    buttonYStart = imgPos(2) + imgPos(4) - buttonHeight - 0.005; % Start from the top of the image
    
    % Create buttons on the right, relative to the image
    uicontrol('Style', 'pushbutton', 'String', 'View Blade Damage Map database', ...
        'Units', 'normalized', 'Position', [buttonX, buttonYStart, buttonWidth, buttonHeight], ...
        'Callback', @viewAvailableBDM, 'FontSize', 14);
    uicontrol('Style', 'pushbutton', 'String', 'Add to Blade Damage Map database', ...
        'Units', 'normalized', 'Position', [buttonX, buttonYStart - buttonHeight - 0.05, buttonWidth, buttonHeight], ...
        'Callback', @addToBDM, 'FontSize', 14);
    uicontrol('Style', 'pushbutton', 'String', 'View Information', ...
        'Units', 'normalized', 'Position', [buttonX, buttonYStart - 2 * (buttonHeight + 0.05), buttonWidth, buttonHeight], ...
        'Callback', @viewInformation, 'FontSize', 14);
    
    % Store handle for access
    handles.hMainFig = hMainFig;
    handles.hSubFig = [];
    guidata(hMainFig, handles);
    
    % Function related to database button
    function viewAvailableBDM(~, ~)

        % Prelocate point cloud information
        virt = importdata('virtual.asc',';');

        [blatabase] = BDM_virtUnpack(virt); % Parsing data to expected format
        clear virt % Clearing memory

        % Load the database
        load('database.mat', 'database');
        
        % Create the figure
        hSubFig = figure('Name', 'Blade Damage Map: Database viewer', 'Units', 'normalized', 'Position', [0.35, 0.35, 0.3, 0.3], 'NumberTitle', 'off');
        
        % Create the dropdown menu
        dropdownItems = arrayfun(@(x) database.(['BDM_', sprintf('%02d', x)]).Name, 1:database.Available_BDM, 'UniformOutput', false);
        hDropdown = uicontrol('Parent', hSubFig, 'Style', 'popupmenu', 'String', dropdownItems, ...
                              'Units', 'normalized', 'Position', [0.2, 0.65, 0.6, 0.2], 'FontSize', 14);
        
        % Create the execute button
        uicontrol('Parent', hSubFig, 'Style', 'pushbutton', 'String', 'Open Case file', ...
                  'Units', 'normalized', 'Position', [0.2, 0.35, 0.6, 0.2], 'FontSize', 14, ...
                  'Callback', @(src, event) executeCallback(hDropdown, database, blatabase));
        
        % Handle the subfigure
        handles.hSubFig = hSubFig;
        guidata(hMainFig, handles);
    end

    % Having chosen the specific dataset
    function executeCallback(hDropdown, database, blatabase)
        % Get the selected item index
        selectedIndex = get(hDropdown, 'Value');
        
        % Construct the field name
        fieldName = sprintf('BDM_%02d', selectedIndex);
        
        % Get the full path to the local BDM_papercode folder
        currentScriptPath = fileparts(mfilename('fullpath'));
        idx = strfind(currentScriptPath, 'BDM_software');
        if isempty(idx)
            error('Current script is not inside the BDM_papercode project.');
        end
        basePath = currentScriptPath(1 : idx + length('BDM_spftware') - 1);
        
        % Combine with stored relative path
        fullPath = fullfile(basePath, database.(fieldName).Address);


        % Retrieve the Case and Address values
        selectedCase = database.(fieldName).Case;
        
        % Case 1 (Wind Farm)
        if selectedCase == 1
            disp('Displaying Case 1 wind farm tracking')
            
            % Loading metadata of dataset
            load(fullfile(fullPath, 'meta.mat'));
            data = load(fullfile(fullPath, [meta.Project_Name '_database.mat']));
            bdDB = data.bdDB; % Struct cleaning
            clear data % 
            
            global ploc % Assigning a global variable to photo location
            ploc = fullfile(basePath, meta.Project_Photos);
            
            % Internal function
            chooseC1mode(hMainFig, bdDB, blatabase); % Start working with dataset
            
        else % Case 2 has been chosen (the only other option)
            disp('Now displaying the Case 2 damage tracking locations! (be patient)')
            
            % Load the metadata of dataset
            load(fullfile(fullPath, 'meta.mat'), 'meta');
            
            % Visualizing the wind turbine blade with damages in Case 2
            BDM_case2_damageVis(blatabase.blade,meta) % External function
        end   
    end
    
    % Window utility 
    function chooseC1mode(hMainFig, bdDB, blatabase)
        hSubFig = figure('Name', 'Blade Damage Map: Choose analysis Mode', ...
            'Units', 'normalized', ...
            'Position', [0.35, 0.35, 0.3, 0.3], ...
            'NumberTitle', 'off');

        % First button: no change needed if it doesn't use blatabase
        uicontrol('Parent', hSubFig, ...
            'Style', 'pushbutton', ...
            'String', 'Mode: Wind farm damage statistics', ...
            'Units', 'normalized', ...
            'Position', [0.2, 0.65, 0.6, 0.2], ...
            'Callback', @(src, event)BDM_case1_stats(src, event, bdDB), ...
            'FontSize', 14);

        % Second button: pass blatabase using anonymous function
        uicontrol('Parent', hSubFig, ...
            'Style', 'pushbutton', ...
            'String', 'Mode: Wind farm damage visualization', ...
            'Units', 'normalized', ...
            'Position', [0.2, 0.35, 0.6, 0.2], ...
            'Callback', @(src, event)BDM_case1_visual(src, event, bdDB, blatabase), ...
            'FontSize', 14);

        % Handle the subfigure
        handles.hSubFig = hSubFig;
        guidata(hMainFig, handles);
    end

    % Initiate working with Case 1 in statistic mode
    function BDM_case1_stats(~, ~, bdDB)
        
        disp('Case 1 statistics module initiated')
        disp('displaying farm layout, inquring about method of analysis')
        BDM_case1_stat_park(bdDB, 0) % External function
        
        chooseC1stats(hMainFig, bdDB) % Internal function
    end


    % Choose statistics display mode
    function chooseC1stats(hMainFig, bdDB)
        hSubFig = figure('Name', 'Blade Damage Map: Statistics module', ...
            'Units', 'normalized', ...
            'Position', [0.35, 0.35, 0.3, 0.3], ...
            'NumberTitle', 'off');

        % First button: no change needed if it doesn't use blatabase
        uicontrol('Parent', hSubFig, ...
            'Style', 'pushbutton', ...
            'String', 'Plot damages across all wind turbines', ...
            'Units', 'normalized', ...
            'Position', [0.2, 0.65, 0.6, 0.2], ...
            'Callback', @(src, event)BDM_case1_stat_dpark(src, event, bdDB, 0,'all'), ...
            'FontSize', 14);

        % Second button: pass blatabase using anonymous function
        uicontrol('Parent', hSubFig, ...
            'Style', 'pushbutton', ...
            'String', 'Plot damage locations along turbine blades', ...
            'Units', 'normalized', ...
            'Position', [0.2, 0.35, 0.6, 0.2], ...
            'Callback', @(src, event)BDM_case1_stat_dblade(src, event, bdDB, 0, 'CsPos', {'All'}, [0 39], 0.25), ...
            'FontSize', 14);

        % Handle the subfigure
        handles.hSubFig = hSubFig;
        guidata(hMainFig, handles);
    end
    
    % Call to external function
    function BDM_case1_visual(~, ~, bdDB, blatabase)
        
        % Visualizing the damages on a standard blade, requires blatabase
        % containing blade point cloud

        disp('Case 1 visualization module initiated')
        BDM_case1_vis_open(bdDB, blatabase, 0, 'all'); % External function
    end

    % Second button, internal functions
    % Adding new datasets to the BDM database
    function addToBDM(~, ~)
        hSubFig = figure('Name', 'Blade Damage Map: Add new case to database', 'Units', 'normalized', 'Position', [0.35, 0.35, 0.3, 0.3], 'NumberTitle', 'off');
        uicontrol('Parent', hSubFig, 'Style', 'pushbutton', 'String', 'Add Case 1', ...
                  'Units', 'normalized', 'Position', [0.2, 0.65, 0.6, 0.2], ...
                  'Callback',@BDM_case1_add, 'FontSize', 14);
        uicontrol('Parent', hSubFig, 'Style', 'pushbutton', 'String', 'Add Case 2', ...
                  'Units', 'normalized', 'Position', [0.2, 0.35, 0.6, 0.2], ...
                  'Callback',@BDM_case2_add, 'FontSize', 14);

        % Handle the subfigure
        handles.hSubFig = hSubFig;
        guidata(hMainFig, handles);
    end

    % View readme file stored in software directory
    function viewInformation(~, ~)
        disp('Displaying Blade Damage Map information')
    
        % Read text from a file
        fileID = fopen('readme.txt', 'r');
        textData = fread(fileID, '*char')';
        fclose(fileID);
        
        % Create the figure window
        hSubFig = figure('Name', 'View Information', 'Units', 'normalized', 'Position', [0.3, 0.3, 0.4, 0.4], 'NumberTitle', 'off');
        hSubFig.WindowState = 'maximized';

        % Create the text box and ensure the text is fully visible
        uicontrol('Parent', hSubFig, 'Style', 'text', 'String', textData, ...
                  'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8], ...
                  'HorizontalAlignment', 'left', 'FontSize', 12);
    end
    
    % Internal function, adding Case 1 calling to external function
    function BDM_case1_add(~, ~)
        
        disp('Case 1 addition started, follow instructions on screen')
        BDM_case1_make % External function
    end

    % Internal function, adding Case 2 calling to external function
    function BDM_case2_add(~, ~)
        
        disp('Case 2 addition started, follow instructions on screen')
        BDM_case2_make % this is the function responsible for adding C2 to BDM
    end
end

