function BDM_case1_vis_dclick(~, ~, photoStr, rpos, comm)

% Function responsible for showing an image of the corresponding damage,
% using global parameters listing the correct image and keeping track how
% many figures have been opened
global figHandles
global ploc

% Deleting all open figures
if strcmp(photoStr,'empty')
    fprintf('All windows closed, you are welcome \n')
    for i = 1:length(figHandles)
        if ishandle(figHandles(i))
            close(figHandles(i))
        end
        
    end
    figHandles = [];
else
    % Plotting the right photo
    fPathPhoto = fullfile(ploc, sprintf('%s.jpg', photoStr{1}) );

    figHandles(end+1) = figure('Name', sprintf('Showing image: %s, At position: %s [m], Comm: %s', photoStr{1}, sprintf('[%.3f]', cell2mat(rpos)), string(comm{1})), 'NumberTitle', 'off'); hold on;
    imshow(fPathPhoto)%, 'InitialMagnification', 'fit');
    

    hold off
end

end


