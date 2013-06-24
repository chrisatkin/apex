function apex(slides)

%% Create the main interface
% Create a window
window = figure('NumberTitle', 'off', ...
                'Name', 'Advanced Planning Experiment', ...
                'WindowStyle', 'normal', ...
                'ResizeFcn', @resizeFcn, ...
                'Toolbar', 'figure', ...
                'MenuBar', 'none', ...
                'WindowKeyReleaseFcn', @keyboardFcn, ...
                'Position', [90 0 700 700]);
            
% Want to use the standard toolbar, except modify it
set(0, 'ShowHidden', 'on')
UT = get(get(window, 'children'), 'children');
delete(UT([1 2 3 5 6 8 12 15 16])); % Remove unneeded icons
[X map] = imread(fullfile('assets', 'camera.gif'));
% set(UT(14), 'CData', ind2rgb(X, map));

% Add our own icons
toolbar = findall(window, 'Type', 'uitoolbar');

    % Save tool
    [X map] = imread(fullfile('assets', 'build.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Save data', ...
               'ClickedCallback', @saveCallback, ...
               'Separator', 'on');
    
    % Load tool
    [X map] = imread(fullfile('assets', 'load.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Load previously saved data', ...
               'ClickedCallback', @loadCallback);
    
    % Erase tool
    [X map] = imread(fullfile('assets', 'erase.gif'));
    erase = uitoggletool('Parent', toolbar, ...
                         'CData', ind2rgb(X, map), ...
                         'TooltipString', 'Erase mode', ...
                         'Separator', 'on');
    
    % Clear tool
    [X map] = imread(fullfile('assets', 'clear.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Clear this slide', ...
               'ClickedCallback', @clearCallback);
                     
    % Constrast tool
    [X map] = imread(fullfile('assets', 'contrast.gif'));
    uitoggletool('Parent', toolbar, ...
                 'CData', ind2rgb(X, map), ...
                 'TooltipString', 'Change the slide contrast', ...
                 'OnCallback', @contrastOn, ...
                 'OffCallback', @contrastOff, ...
                 'Separator', 'on');
            
    % High-power zoom
    [X map] = imread(fullfile('assets', 'zoom.gif'));
    uitoggletool('Parent', toolbar, ...
                 'CData', ind2rgb(X, map), ...
                 'TooltipString', 'High-powered zoom', ...
                 'OnCallback', @zoomOn, ...
                 'OffCallback', @zoomOff);
    
    % Copy button
    [X map] = imread(fullfile('assets', 'copy.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Copy the boundary in this layer', ...
               'ClickedCallback', @copyCallback, ...
               'Separator', 'on');
           
    % Paste button
    [X map] = imread(fullfile('assets', 'paste.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Paste the boundary data to this layer', ...
               'ClickedCallback', @pasteCallback);
           
    % Undo button
    [X map] = imread(fullfile('assets', 'undo.gif'));
    uipushtool('Parent', toolbar, ...
               'CData', ind2rgb(X, map), ...
               'TooltipString', 'Undo the last click in this layer', ...
               'ClickedCallback', @undoCallback, ...
               'Separator', 'on');

% -------------------------------------------------------------------------

%% Initialize the APEX/F interface
% Create a viewer
viewer = Viewer(window);

for i = 1 : numel(slides)
    viewer.assignSlice(i);
    
    viewer.assignLayer(i, 'background', 'Bitmap');
    viewer.assignLayer(i, 'points', 'Point');
    viewer.assignLayer(i, 'interpolation', 'Interpolation');
    
    [height width] = size(slides{i});
    
    viewer.setLayerCData(i, 'background', slides{i});
    viewer.setLayerCData(i, 'points', zeros(height, width));
    viewer.setLayerAlphaData(i, 'points', zeros(height, width));
    
    viewer.setLayerActive(i, 'background', true);
    viewer.setLayerActive(i, 'points', true);
    
    viewer.addSliceButtonDownListener(i, 'background', @(x, y, parent) fprintf('(%i, %i) clicked in background\n', x, y));
    viewer.addSliceButtonDownListener(i, 'points', @pointsLayerCallback);
%     viewer.addSliceButtonMotionListener(i, 'points', @pointsLayerCallback);
end

viewer.setSliceVisibility(1, 'on');
viewer.addSliceButtonMotionListener(viewer.getVisibleSlice(), 'points', @pointsLayerCallback);

% -------------------------------------------------------------------------
% Add a spinner
s = spinner('Parent', window, ...
            'Position', [10 20 60 30], ...
            'Min', 1, ...
            'Max', numel(slides), ...
            'StartValue', 1, ...
            'Step', 1, ...
            'Callback', @spinnerCallback);

% -------------------------------------------------------------------------

    % ---------------------------------------------------------------------
    % Callbacks
    % ---------------------------------------------------------------------

    function pointsLayerCallback(x, y, parent)
        fprintf('Point layer clicked at (%i, %i) on %i \n', x, y, viewer.getVisibleSlice());
        
%         get(erase, 'State')
        
        if strcmp(get(erase, 'State'), 'off')
            try
                parent.addClickToStack(x, y);
                parent.paint(x, y);
            catch exception
                if strcmp(exception.identifier, 'PointLayerException:InvalidPaintCoordinate')
                    % Do nothing!
                    ;
                else
                    rethrow(exception);
                end
            end
        elseif strcmp(get(erase, 'State'), 'on')
            % I swear, I cannot find a better way of doing this...
            % No, I'm not proud. But so be it.
            parent.removeClickFromStack(x, y);
            parent.unpaint(x, y);
            
            parent.removeClickFromStack(x - 1, y);
            parent.unpaint(x - 1, y);
            
            parent.removeClickFromStack(x + 1, y);
            parent.unpaint(x + 1, y);
            
            parent.removeClickFromStack(x, y - 1);
            parent.unpaint(x, y - 1);
            
            parent.removeClickFromStack(x, y + 1);
            parent.unpaint(x, y + 1);
            
            parent.removeClickFromStack(x - 1, y - 1);
            parent.unpaint(x - 1, y - 1);
            
            parent.removeClickFromStack(x + 1, y + 1);
            parent.unpaint(x + 1, y + 1);
            
            parent.removeClickFromStack(x - 1, y + 1);
            parent.unpaint(x - 1, y + 1);
            
            parent.removeClickFromStack(x + 1, y - 1);
            parent.unpaint(x + 1, y - 1);
        else
            throw(MException('ApexException:ToggleStateNotPossible', '%s is not a possible toggle state, check your universe hasnt crashed', get(erase, 'State')));
        end
    end
    
    function resizeFcn(hObject, eventdata, handles)
%         disp('In resize')
%         position = get(window, 'Position');
%         width = position(3);
%         height = position(4);
    end

    function keyboardFcn(hObject, eventdata)
        switch eventdata.Key
            % Remember that switches don't fall through
            case 'i'
                if strcmp(viewer.getLayerVisibility(viewer.getVisibleSlice(), 'interpolation'), 'on')
%                     disp('Interpolation layer IS visible');
                    viewer.setLayerActive(viewer.getVisibleSlice(), 'interpolation', false);
                    viewer.setLayerActive(viewer.getVisibleSlice(), 'points', true);
                    viewer.setLayerVisible(viewer.getVisibleSlice(), 'points', 'on');
                    viewer.setLayerVisible(viewer.getVisibleSlice(), 'interpolation', 'off');
                    
                    viewer.addSliceButtonMotionListener(viewer.getVisibleSlice(), 'points', @pointsLayerCallback);
                else
%                     disp('Interpolation layer IS NOT visible');
                    viewer.setLayerActive(viewer.getVisibleSlice(), 'interpolation', true);
                    viewer.setLayerVisible(viewer.getVisibleSlice(), 'interpolation', 'on');
                    viewer.displayInterpolation(viewer.getVisibleSlice(), 'points', 'interpolation');
                    viewer.addSliceButtonDownListener(viewer.getVisibleSlice(), 'interpolation', @interpolateLayerCallback);
                    
                    viewer.removeSliceButtonMotionListener(viewer.getVisibleSlice(), 'points');
                end
                
            case 'uparrow'
                viewer.dilateLayerSelection(viewer.getVisibleSlice(), 'interpolation', 1);
                
            case 'downarrow'
                viewer.erodeLayerSelection(viewer.getVisibleSlice(), 'interpolation', 1);
        end
    end

    function interpolateLayerCallback(x, y, parent)
        parent.toggleInterpolationPixel(x, y);
        parent.drawInterpolation(0.5);
    end

    function saveCallback(hObject, eventdata, handles)
        disp('Saving');
        dir = uigetdir(fullfile(pwd, 'data'), 'Select directory...');
        
        if dir == 0
            return
        end
        
        function saveEach(i, object)
            
            this_dir = fullfile(dir, ['slide-', num2str(i)]);
            mkdir(this_dir);
            
            switch strrep(char(class(object)), 'Layer', '')
                case 'Bitmap'
                    % Do nothing, we already have everything we need from
                    % here
                case 'Point'
                    % Save the stack and CData
                    if object.getStackSize() > 0
                        dlmwrite(fullfile(this_dir, 'stack.apex-result'), object.getStack());
                        dlmwrite(fullfile(this_dir, 'point-mask.apex-result'), object.getCData());
                    end
                case 'Interpolation'
                    % Write the interpolation
                    if object.isActive()
                        dlmwrite(fullfile(this_dir, 'mask.apex-result'), object.getInterpolation());
                        imwrite(object.getInterpolation(), fullfile(this_dir, 'mask.tiff'), 'tiff');
                        
                        dlmwrite(fullfile(this_dir, 'boundary.apex-result'), object.getBoundary());
                    end
                otherwise
                    throw(MException('ApexException:InvalidLayerIdentifier:saveCallback', 'Layer type is not Bitmap, Point or Interpolation'));
            end
        end
        
        viewer.each(@saveEach);
    end

    function loadCallback(hObject, eventdata, handles)
        dir = uigetdir(fullfile(pwd, 'data'), 'Select directory...');
        
        if dir == 0
            return
        end
        
        function loadEach(i, object)
            this_dir = fullfile(dir, ['slide-', num2str(i)]);

            if exist(this_dir, 'file') == 7
                
                switch strrep(char(class(object)), 'Layer', '')
                    case 'Bitmap'
                        % Do nothing
                    case 'Point'
                        object.clear();
                        
                        if exist(fullfile(this_dir, 'stack.apex-result'), 'file') == 2
                            object.setStack(dlmread(fullfile(this_dir, 'stack.apex-result')));
                        end
                        
                        if exist(fullfile(this_dir, 'point-mask.apex-result'), 'file') == 2
                            object.setCData(dlmread(fullfile(this_dir, 'point-mask.apex-result')));
                            object.setAlphaData(dlmread(fullfile(this_dir, 'point-mask.apex-result')));
                        end
                        
                        object.setActive(true);
                    case 'Interpolation'
                        
                        if exist(fullfile(this_dir, 'mask.apex-result'), 'file') == 2
                            disp('Interpolation');
                            object.clear();
                            
                            object.setInterpolation(dlmread(fullfile(this_dir, 'mask.apex-result')));
                            viewer.addSliceButtonDownListener(i,  'interpolation', @interpolateLayerCallback);
                            object.drawInterpolation(0.5);
                            object.setActive(true);
                            
                            % Turn off the points layer
                            viewer.setLayerActive(i, 'points', false);
                        else
                            disp('Not interpolation');
                        end
                    otherwise
                        throw(MException('ApexException:InvalidLayerIdentifier:loadCallback', 'Layer type is not Bitmap, Point or Interpolation'));
                end
            end
            
        end
        
        viewer.each(@loadEach);
        viewer.setSliceVisibility(1, 'on');
        viewer.removeSliceButtonMotionListener(viewer.getVisibleSlice(), 'points');
    end

    function spinnerCallback(hObject, eventdata, handles)
        viewer.removeSliceButtonMotionListener(viewer.getVisibleSlice(), 'points');
        viewer.setSliceVisibility(get(s, 'Value'), 'on');
        viewer.addSliceButtonMotionListener(viewer.getVisibleSlice(), 'points', @pointsLayerCallback);

    end

    function contrastOn(hObject, event, handles)
        viewer.setConstrastEnabled(viewer.getVisibleSlice(), 'background', 'on');
    end

    function contrastOff(hObject, event, handles)
        viewer.setConstrastEnabled(viewer.getVisibleSlice(), 'background', 'off');
    end

    function zoomOn(hObject, event, handles)
        viewer.setZoomEnabled(viewer.getVisibleSlice(), 'background', 'on');
    end

    function zoomOff(hObject, event, handles)
        viewer.setZoomEnabled(viewer.getVisibleSlice(), 'background', 'off');
    end

    function copyCallback(hObject, event, handles)
       viewer.setCopySlice(viewer.getVisibleSlice()); 
    end

    function pasteCallback(hObject, event, handles)
        viewer.removeSliceButtonMotionListener(viewer.getVisibleSlice(), 'points');
        viewer.triggerPaste(viewer.getVisibleSlice(), {'Point', 'Interpolation'});
        viewer.addSliceButtonDownListener(viewer.getVisibleSlice(), 'interpolation', @interpolateLayerCallback);
    end

    function undoCallback(hObject, event, handles)
        viewer.undoLastClick(viewer.getVisibleSlice(), 'points');
    end

    function clearCallback(hObject, event, handles)
        viewer.clearLayer(viewer.getVisibleSlice(), 'points');
    end
end