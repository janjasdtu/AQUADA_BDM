function BDM_case1_make

% Function responsible for converting .xlsx sheet into a database entry for
% BDM format. Creates 'meta.mat' in the pointed to directory. Expects an
% image folder to be present with the 

fprintf('Case 1 ingest has begun. Follow window prompts; look to cmd window for feedback \n')

% Get the project name
projectName = getProjectName();

% Select the project folder
projectFolder = selectProjectFolder();

% Updating the BDM database
updateDatabase(projectName, projectFolder)

disp('Database updated with new C1 entry.')

%% Running the database assembly, with internal functions

bdDB = init_c1DB; % Specify metadata (blade length most important)

[bdDB,filePath] = turb_c1DB(bdDB,projectFolder); % Designate turbine IDs and XY locations

bdDB = blade_c1DB(bdDB,filePath); % Designate blade IDs in relation to turbine IDs

bdDB = damage_c1DB(bdDB,filePath); % Assign damages to individual blades

% Saving metadata of the created database entry
disp('Database has now been mapped, saving information and closing.')
meta.Project_Name = projectName; meta.Project_Folder = projectFolder;
meta.Project_Photos = [meta.Project_Folder,'\photos'];
save(fullfile(projectFolder, 'meta.mat'), 'meta');

save(fullfile(projectFolder, [projectName, '_database.mat']), 'bdDB');

%% Database creation functions

% Type in the metadata of the wind farm
function bdDB = init_c1DB

    % Create the prompt window
    prompt = {'Park Name:', ...
              'Park Type:', ...
              'Country:', ...
              'Operator:', ...
              'WT Type:', ...
              'Inspection Campaign:', ...
              'Blade Length (m):'};
    
    dlgTitle = 'Enter Blade Database Information';
    numLines = [1 100];
    defaultAnswers = {'', '', '', '', '', '', '0'};
    
    % Display input dialog
    userInput = inputdlg(prompt, dlgTitle, numLines, defaultAnswers);
    
    % Check if user clicked OK
    if ~isempty(userInput)
        % Assign inputs to struct
        bdDB.parkname    = userInput{1};
        bdDB.parkType    = userInput{2};
        bdDB.country     = userInput{3};
        bdDB.operator    = userInput{4};
        bdDB.wtType      = userInput{5};
        bdDB.inspCamp    = userInput{6};
        bdDB.bladeLength = str2double(userInput{7});  % Convert string to number
    else
        disp('User cancelled input.');
    end

end

% Continue with data input, define turbine sheet and columns
function [bdDB,filePath] = turb_c1DB(bdDB,folderPath)

    % Ensure folderPath is valid
    if ~exist('folderPath', 'var') || ~isfolder(folderPath)
        folderPath = uigetdir('Select folder containing Excel files');
    end

    % List Excel files
    files = dir(fullfile(folderPath, '*.xlsx'));
    fileNames = {files.name};

    % Let user choose a file
    [selectedFileIdx, ok] = listdlg('PromptString', 'Select an Excel file:', ...
        'SelectionMode', 'single', ...
        'ListString', fileNames, ...
        'ListSize', [300, 300]);
    if ~ok, return; end

    filePath = fullfile(folderPath, fileNames{selectedFileIdx});

    % Get sheet names
    [~, sheetNames] = xlsfinfo(filePath);

    % Let user choose a sheet
    [selectedSheetIdx, ok] = listdlg('PromptString', 'Select a tab containing turbine information:', ...
        'SelectionMode', 'single', ...
        'ListString', sheetNames, ...
        'ListSize', [300, 300]);
    if ~ok, return; end

    selectedSheet = sheetNames{selectedSheetIdx};

    % Read selected sheet
    data = readtable(filePath, 'Sheet', selectedSheet, 'VariableNamingRule','preserve');

    % Prompt user to select required columns
    requiredCols = {'WTInstallationNumber', 'WTGID', 'CoordX', 'CoordY'};
    availableCols = data.Properties.VariableNames;

    selectedCols = cell(1, numel(requiredCols));
    for i = 1:numel(requiredCols)
        [idx, ok] = listdlg('PromptString', ['Select column for: ', requiredCols{i}], ...
            'SelectionMode', 'single', ...
            'ListString', availableCols, ...
            'ListSize', [400, 300]);  % Larger window
        if ~ok, return; end
        selectedCols{i} = availableCols{idx};
    end

    % Create bdDB.turbines table
    bdDB.turbines = table(data.(selectedCols{1}), ...
        data.(selectedCols{2}), ...
        data.(selectedCols{3}), ...
        data.(selectedCols{4}), ...
        'VariableNames', requiredCols);

end

% Continue on the same file, define blade sheet
function bdDB = blade_c1DB(bdDB,filePath)

    % Get sheet names
    [~, sheetNames] = xlsfinfo(filePath);

    % Let user choose a sheet
    [selectedSheetIdx, ok] = listdlg('PromptString', 'Select a tab containing blade information:', ...
        'SelectionMode', 'single', ...
        'ListString', sheetNames, ...
        'ListSize', [300, 300]);
    if ~ok, return; end

    selectedSheet = sheetNames{selectedSheetIdx};

    % Read selected sheet
    data = readtable(filePath, 'Sheet', selectedSheet, 'VariableNamingRule','preserve');

    % Prompt user to select required columns
    requiredCols = {'BladeID', 'WTGID', 'TurbinebladeID'};
    availableCols = data.Properties.VariableNames;

    selectedCols = cell(1, numel(requiredCols));
    for i = 1:numel(requiredCols)
        [idx, ok] = listdlg('PromptString', ['Select column for: ', requiredCols{i}], ...
            'SelectionMode', 'single', ...
            'ListString', availableCols, ...
            'ListSize', [400, 300]);  % Larger window
        if ~ok, return; end
        selectedCols{i} = availableCols{idx};
    end

    % Create bdDB.blades table
    bdDB.blades = table(data.(selectedCols{1}), ...
        data.(selectedCols{2}), ...
        data.(selectedCols{3}), ...
        'VariableNames', requiredCols);

end

% Finalize ingestion, define damages per blade
function bdDB = damage_c1DB(bdDB, filePath)

    % Get sheet names
    [~, sheetNames] = xlsfinfo(filePath);

    % Let user choose a sheet
    [selectedSheetIdx, ok] = listdlg('PromptString', 'Select a tab containing damage information:', ...
        'SelectionMode', 'single', ...
        'ListString', sheetNames, ...
        'ListSize', [300, 300]);
    if ~ok, return; end

    selectedSheet = sheetNames{selectedSheetIdx};

    % Read selected sheet
    data = readtable(filePath, 'Sheet', selectedSheet, 'VariableNamingRule','preserve');

    % Friendly names shown to the user
    requiredCols = {'Inspection date', 'Engineer', 'Blade number', 'Blade damage #', 'Severity', 'Type', 'Depth', ...
        'Damage area cross-section position', 'Damage area radial position, m', 'Damage area radial size, m', ...
        'Damage size,m', 'Damage density, %', 'Damage orientation, deg.', 'Damage photo #', ...
        'Inspection comment', 'Analyser comment'};

    % Actual output column names in the resulting table
    actualCols = {'InspDate', 'Engineer', 'BladeID', 'No', 'Severity', 'Type', 'Depth', ...
        'CsPos', 'RPos', 'DaRSize', 'Size', 'Dens', ...
        'Ori', 'PhotoNo', 'InspComm', 'AnlComm'};

    availableCols = data.Properties.VariableNames;

    % Prompt user to map each required column to an actual column
    selectedCols = cell(1, numel(requiredCols));
    for i = 1:numel(requiredCols)
        [idx, ok] = listdlg('PromptString', ['Select actual column for: "' requiredCols{i} '"'], ...
            'SelectionMode', 'single', ...
            'ListString', availableCols, ...
            'ListSize', [400, 300]);
        if ~ok, return; end
        selectedCols{i} = availableCols{idx};
    end

    % Build the output table using actual data but actualCols as variable names
    damageData = table();
    for i = 1:numel(actualCols)
        damageData.(actualCols{i}) = data.(selectedCols{i});
    end

    % Store in bdDB
    bdDB.damages = damageData;
end


%% Database function repository, internal calls

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


% Update the database file, after new dataset has been introduced
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
    newSubStruct.Case = 1;

    % Add the new sub-struct to the database
    database.(['BDM_0', num2str(newBDM)]) = newSubStruct;

    % Save the updated database back to the file
    save('database.mat', 'database');
end


end
