function BDM_case2_DmgLocClick(~, ~, Adress,value)

% Function responsible for showing images sequentially from the specified folder in one figure window
global figHandles % Checking how many sequences have been opened

% Get list of all image files in the specified folder
imageFiles = dir(fullfile(Adress, '*.jpg'));
pDur = 3 / length(imageFiles);
% Check if there are any images in the folder
if isempty(imageFiles)
    fprintf('No images found in the specified folder.\n');
    return;
end
% Deleting all open figures
for i = 1:length(figHandles)
    if value == true
        close(figHandles(i))
    end
end

figHandles = [];

% Create a new figure window
figHandles(end+1) = figure('Name', 'Showing images sequentially', 'NumberTitle', 'off'); hold on;

% Loop through each image and display it sequentially in the same figure window
for i = 1:length(imageFiles)
    fPathPhoto = fullfile(Adress, imageFiles(i).name);
    imshow(fPathPhoto);
    
    % Display the image title above the image in bold letters
    title(imageFiles(i).name, 'Interpreter', 'none');
    
    % Pause to allow viewing the image before moving to the next one
    pause(pDur); % Adjust the pause duration as needed
end

hold off;
fprintf('All images displayed sequentially.\n');

end


