%% Viewer
% A |Viewer| class is the highest level abstraction in the system. It is an
% abstraction for multiple |Slice| s. The philosophy is that the user should
% issue commands to |Viewer| classes, which then performs the tasks on
% behalf of the users. Usually, these are high-level operations (such as
% copy and paste), and any additional non-trivial functionality should be
% added by adding an appropriate method within |Viewer|. _However_, because
% of the nature of |Viewer|, most of the functionality provided is routing
% to the appropriate |Layer|. Still, |Viewer| is an important abstraction
% within the APEX graphical stack.
%
% |Viewer| contains multiple Slices, which are stored as a |struct()|
% identified by |obj.Handles| (notice the importance of the capital 'H').
% Instantiating a |Viewer| will create an |axes| object and some associated
% graphical elements.
% 
%% Copy and Pasting
% The copy and pasting mechanism appears complicated, and yet is rather
% simple.
%
% Within |Viewer|, the |copy_slice| property contains the ID of the slice
% to be copied. When the triggerPaste methods is called, |Viewer| delegates
% to |Slice.copyFromSlice|, whilst passing the |Slice| to be copied from -
% this is the copy slice (CS).
%
% |Layer| defines three abstract methods, |hasDataForCopy|,
% |getDataForCopy| and |setCopyData|. These methods must be implemented on
% each of the |Layer| subclasses (|BitmapLayer|, |PointLayer| and
% |InterpolationLayer|).
%
%  methods (Abstract)
%     has_data = hasDataForCopy(obj);
%     data = getDataForCopy(obj);
%     setCopyData(obj, data);
%  end
%
% If the CS returns true for |hasCopyData|, then |getDataForCopy| is
% called. The result of this is called to |setCopyData| on the target
% layer. Because each layer type implements these methods, the data is
% correctly assigned.
%
% *APEX/F Documentation*
%
% * <bootstrap.html Architecture and Bootstrapping>
% * <Viewer.html Viewer>
% * <Slice.html Slice>
% * <Layer.html Layer>
% * <BitmapLayer.html BitmapLayer>
% * <PointLayer.html PointLayer>
% * <InterpolationLayer.html InterpolationLayer>
%
% <<general-arch.png>>
%
classdef Viewer < handle
    %% Properties (Private)
    % *|parent|*: the parent figure to which a Viewer should be attached. An
    % |axes| will be created within |parent|.
    %
    % *|active_slice|*: the |Slice| that is currently visible.
    %
    % *|copy_slice|*: the slice to which the data is to be copied from. The
    % copy and paste system will be explained further within this document.
    %
    % *|Handles|*: a |struct()| containing Handles. |Handles.slices|
    % contains |Slice| objects.
    properties (Access = private)
        parent
        active_slice
        copy_slice
        Handles
    end
    
    methods (Access = public)
        %% Viewer (constructor)
        % Instantiate an instance of |Viewer|. Some graphical elements will
        % also be created, such as a |uipanel|. The details of the
        % |uipanel| are abstracted away from the user. The colormap of the
        % |axes| will also be set to *bone* (because this map is the most
        % appropriate for CT scan data).
        %
        % *Parameters*
        %
        % |parent|: figure handle in which to place the Viewer.
        function obj = Viewer(parent)
            obj.parent = parent;
            
            % Create GUI elements
            obj.Handles.panel = uipanel('Parent', obj.parent);
            obj.Handles.axis = axes('Parent', obj.Handles.panel, ...
                                    'YDir', 'reverse', ...
                                    'Units', 'pixels');
                                
            obj.Handles.slices = struct();
            obj.active_slice = 1;
            obj.copy_slice = false;
            
            % Change properties of the 
%             hold(obj.Handles.axis, 'on');
            colormap(obj.Handles.axis, 'bone');
        end
        
        %% setSize (unused)
        % Change the size of the |uipanel|.
        %
        % *Parameters*
        %
        % |dims|: 1*4 matrix containing |[left bottom width height]| values.
        % Remembers that the bottom left hand corner of the figure is (0,
        % 0).
        function setSize(obj, dims)
            set(obj.Handles.panel, 'Position', dims);
        end
        
        %% assignSlice
        % Create a new slice and add it to the |Viewer|. The order of
        % creation *is* important, although somewhat insignificant until
        % |Layer| s are added to the slice. Slices cannot be re-ordered
        % after assignment.
        %
        % *Parameters*
        %
        % |id|: the identifier of the newly created |Slice|.
        function assignSlice(obj, id)
            if obj.checkSliceExists(id)
                throw(MException('ViewerException:sliceExists:assignSlice', 'Slice %s already exists', id));
            end
            
            obj.Handles.slices.(['slice', num2str(id)]) = Slice(obj.Handles.axis, id);
        end
        
        %% assignLayer
        % Create a new |Layer| (with a name and kind). Data assignments to
        % the |Layer| are performed with separate methods to avoid
        % duplication of effort.
        %
        % *Parameters*
        %
        % |slice_id|: the ID of the |Slice| in which to create the |Layer|
        %
        % |layer_name|: the string identifier of the |Layer|
        %
        % |layer_kind|: the type of the layer created. Must be one of:
        %
        % * |Bitmap|
        % * |Point|
        % * |Interpolation|
        %
        % If this is not the case, a |SliceException| is thrown.
        %
        % Different types of |Layer| are described in the <Layer.html
        % appropriate documentation>.
        function assignLayer(obj, slice_id, layer_name, layer_kind)
            if ~ obj.checkSliceExists(slice_id)
                throw(MException('ViewerException:sliceNotExist:assignLayer', '%s is not a valid slice identifier', slice_id));
            end
            
            obj.Handles.slices.(['slice', num2str(slice_id)]).assignLayer(layer_kind, layer_name);
        end
        
        %% addSliceButtonDownListener
        % Assign a callback to execute upon mouse *click* (_not_
        % dragging!). The callback will execute in the scope of the |Layer|
        % object. Further documentation on this mechanism can be found
        % within the <Layer.html Layer documentation>.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addSliceButtonDownListener(obj, slice, layer, fcn)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:addsliceButtonDownListener', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).addLayerButtonDownListener(layer, fcn);
        end
        
        %% addSliceButtonUpListener
        % Similar to |Viewer.addSliceButtonDownListener|, except fires upon
        % mouse _up_.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addSliceButtonUpListener(obj, slice, layer, fcn)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:addsliceButtonUpListener', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).addLayerButtonUpListener(layer, fcn);
        end
        
        %% addSliceButtonMotionListener
        % Similar to |Viewer.addSliceButtonDownListener| and
        % |Viewer.addSliceButtonUpListener|, except fires upon mouse drag.
        % *Note that only one Motion Listener should be attached at any
        % given time. This is due to a limiation within MATLABs listener
        % architecture  whereby a listener is attached to a |figure| and
        % not an |image|, like in Button Listeners*.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addSliceButtonMotionListener(obj, slice, layer, fcn)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:addSliceButtonMotionListener', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).addLayerButtonMotionListener(layer, fcn);
        end
        
        %% removeSliceButtonMotionListener
        % Removes a Motion Listener from the identified slice.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        function removeSliceButtonMotionListener(obj, slice, layer)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:removeSliceButtonMotionListener', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).removeLayerButtonMotionListener(layer);
        end
        
        %% setLayerCData
        % Sets the CData for a given |Layer|.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |data|: 2-dimensional (|n*m|) data to be applied. Follows normal
        % rules for CData.
        function setLayerCData(obj, slice, layer, data)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setSliceCData', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).setLayerCData(layer, data);
        end
        
        %% setLayerAlphaData
        % Sets the AlphaData for a given |Layer|.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |data|: 2-dimensional (|n*m|) data to be applied. Follows normal
        % rules for AlphaData. Should be a binary image.
        function setLayerAlphaData(obj, slice, layer, data)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setSliceAlphaData', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).setLayerAlphaData(layer, data);
        end
        
        %% setLayerVisible
        % Set a layers visibility. Note that the slice within which the layer
        % is contained must also be visible if setting this to |on|. Details of the possible states
        % for |Layer| objects are found within the <Layer.html Layer
        % documentation>.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer to which to attach the
        % callback
        %
        % |visibility|: |char matrix|, either |on| or |off|. Follows normal rules
        % for MATLAB image handle visibilities.
        function setLayerVisible(obj, slice, layer, visibility)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setLayerVisible', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).setLayerVisibility(layer, visibility);
        end
        
        %% setLayerActive
        % Set whether a layer is active. See the <Layer.html Layer
        % documentation> for details on the relationship between visibility
        % and activity for |Layer| objects.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: string identifier of the layer within which is being
        % adjusted
        %
        % |active|: a *|bool|* representing the activity of the layer.
        function setLayerActive(obj, slice, layer, active)
            obj.Handles.slices.(['slice', num2str(slice)]).setLayerActive(layer, active);
        end
        
        %% setSliceVisibility
        % Slice visibility is an amalgamation of the visibility of
        % constituent |Layer| objects. If a |Layer| is visible, only
        % |Layer| objects contained within that |Layer| _and_ are also
        % visibile are visible within the axes.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |visibility|: new visibility of the slice. Must be |on| or
        % |off|, any other values cause a |SliceException| to be thrown.
        % Follows similar rules to image object visibilities.
        function setSliceVisibility(obj, slice, visibility)
            % Check slice exists
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setSliceVisibility', '%s is not a valid slice identifier', slice));
            end
            
            % Slice does exist, so assign a new visibility.
            switch visibility
                case 'on'
                    % Turn the "old" slice off
                    obj.Handles.slices.(['slice', num2str(obj.active_slice)]).setVisible('off');
                    
                    % Turn the new one on
                    obj.Handles.slices.(['slice', num2str(slice)]).setVisible('on');
                    
                    % Update the "old" slice
                    obj.active_slice = slice;
                case 'off'
                    % Turn the "old" slice off
                    obj.Handles.slices.(['slice', num2str(obj.active_slice)]).setVisible('off');
                    
                    % We no longer have an active slice
                    obj.active_slice = [];
                otherwise
                    throw(MException('ViewerException:invalidSliceVisibility:setSliceVisibility', '%s is not a valid slice visibility mode', visibility));
            end
        end
        
        %% getVisibleSlice
        % Return the ID of the currently visible slice
        %
        % *Returns*
        %
        % |slice|: ID of the currently visible |Slice|. Type is |int32|.
        function slice = getVisibleSlice(obj)
%             fprintf('Visible slice is %i\n', obj.active_slice)
            slice = obj.active_slice;
        end
        
        %% getLayerVisibility
        % Get the visibility of a |Layer| within a |Slice|.
        %
        % *Parameters*
        %
        % |slice|: ID of the slice within which |layer| exists
        %
        % |layer|: |string| identifier of the |Layer| being queried
        %
        % *Returns*
        %
        % |visible|: |string| (|on| or |off|) of the |layer|
        function visible = getLayerVisibility(obj, slice, layer)
            visible = obj.Handles.slices.(['slice', num2str(slice)]).getLayerVisibility(layer);
        end
    
        %% displayInterpolation
        % Display an interpolation. Points are taken from a |PointLayer|
        % and displayed on an _already existing_ |InterpolationLayer|.
        % These layers *must* already exist, they cannot be created within
        % this method. After interpolation, appropriate visibilites and
        % activites of the layers are set; the |InterpolationLayer| is set
        % to active and visible, the |PointLayer| is set to inactive and
        % invisible.
        %
        % *Parameters*
        %
        % |slice|: slice ID of the |Slice| within which to perform the
        % interpolaton
        %
        % |point_layer|: |Layer| of type |PointLayer| from which the stack
        % of points is taken.
        %
        % |interpolation_layer|: the layer of type |InterpolationLayer|
        % upon which the interpolation should be displayed
        function displayInterpolation(obj, slice, point_layer, interpolation_layer)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:displayInterpolation', '%s is not a valid slice identifier', slice));
            end
            
%             try
                % Interpolate from point_layer to interpolation_layer
                obj.Handles.slices.(['slice', num2str(slice)]).interpolateFromPointLayer(point_layer, interpolation_layer);
                
                % Set interpolation_layer to active and visible
                obj.setLayerActive(slice, interpolation_layer, true);
                obj.setLayerVisible(slice, interpolation_layer, 'on');
            
                % Set point_layer to inactive and invisible
                obj.setLayerActive(slice, point_layer, false);
                obj.setLayerVisible(slice, point_layer, 'off');
%             catch exception
%                 warndlg(exception.message, 'APEX');
% 				exception.stack.file
% 				exception.stack.name
% 				exception.stack.line
%             end
        end
        
        %% dilateLayerSelection
        % Perform the dilation morphological operation upon an
        % |InterpolationLayer|. The dilation uses a disk kernel.
        %
        % *Parameters*
        %
        % |slice|: slice ID within which the |InterpolationLayer| is
        % contained
        %
        % |layer|: string identifier of the |InterpolationLayer|
        %
        % |by|: pixel value to dilate by. Note that 1 is added to this
        % value in order to gain an accurate dilation amount.
        function dilateLayerSelection(obj, slice, layer, by)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:dilateLayerSelection', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).dilateLayerSelection(layer, by);
        end
        
        %% erodeLayerSelection
        % Perform the erosion morphological operation upon an
        % |InterpolationLayer|. The erosion uses a disk kernel.
        %
        % *Parameters*
        %
        % |slice|: slice ID within which the |InterpolationLayer| is
        % contained
        %
        % |layer|: string identifier of the |InterpolationLayer|
        %
        % |by|: pixel value to erode by. Note that 1 is added to this
        % value in order to gain an accurate erosion amount.
        function erodeLayerSelection(obj, slice, layer, by)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:erodeLayerSelection', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).erodeLayerSelection(layer, by);
        end
        
        %% each
        % Execute a callback within the context of each |Layer| within all
        % |Layer| objects. A typical callback function looks like:        
        % 
        %  function callback(i, layer)
        %     do_action(layer);
        %  end
        % 
        % Where |i| is the current |Layer| ID and |layer| is the current
        % |Layer| object. Remember that unless ones uses |class(layer)|,
        % the type of |layer| must be assumed as |Layer|. Examples of this
        % usage are the |saveCallback| and |loadCallback| within |apex.m|.
        %
        % *Parameters*
        %
        % |fcn|: function handle or anonymous function to be executed in
        % each |Layer| object within the system
        function each(obj, fcn)
            fh = fieldnames(obj.Handles.slices);
            for i = 1 : length(fh)
                obj.Handles.slices.(fh{i}).doAction(i, fcn);
            end
        end
        
        %% setContrastEnabled
        % Enable the contrast viewer on a |BitmapLayer|.
        %
        % *Parameters*
        %
        % |slice|: slice ID within which |layer| is contained
        %
        % |layer|: layer ID for which the contrast tool should be enabled
        %
        % |enabled|: |bool| representing state of contrast tool
        function setConstrastEnabled(obj, slice, layer, enabled)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setConstrastEnabled', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).setContrastEnabled(layer, enabled);
        end
        
        %% setContrastEnabled
        % Enable the high-powered zoom on a |BitmapLayer|.
        %
        % *Parameters*
        %
        % |slice|: slice ID within which |layer| is contained
        %
        % |layer|: layer ID for which the high-powered zoom should be enabled
        %
        % |enabled|: |bool| representing state of high-powered zoom
        function setZoomEnabled(obj, slice, layer, enabled)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setConstrastEnabled', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).setZoomEnabled(layer, enabled);
        end
        
        %% setCopySlice
        % Assign the slice to be copied from
        %
        % *Parameters*
        %
        % |slice|: the slice ID to be copied from
        function setCopySlice(obj, slice)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:setCopySlice', '%s is not a valid slice identifier', slice));
            end
            
            obj.copy_slice = slice;
        end
        
        %% triggerPaste
        % Trigger the pasting mechanism (see above for details).
        %
        % *Parameters*
        %
        % |slice|: the slice ID of the target slice
        %
        % |to_copy|: cell array of |char| describing which layers to copy
        % (usually |{'Point', 'Interpolation'}|).
        function triggerPaste(obj, slice, to_copy)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:triggerPaste', '%s is not a valid slice identifier', slice));
            end
            
            if obj.copy_slice == false
                warndlg('Need to copy first!', 'APEX/F');
                return
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).copyFromSlice(obj.Handles.slices.(['slice', num2str(obj.copy_slice)]), to_copy);
        end
        
        %% undoLastClick
        % Undo the last click in the specified |PointLayer|. This can be
        % called |n| times, where |n| is the number of points within the
        % layer.
        %
        % *Parameters*
        %
        % |slice|: slice ID containing the target layer
        %
        % |layer|: the layer to undo the click on. Must be a |PointLayer|
        % identifier, otherwise a |SliceException| is thrown.
        function undoLastClick(obj, slice, layer)
            if ~ obj.checkSliceExists(slice)
                throw(MException('ViewerException:sliceNotExist:undoLastPoint', '%s is not a valid slice identifier', slice));
            end
            
            obj.Handles.slices.(['slice', num2str(slice)]).undoLastClick(layer);
        end
        
        %% clearLayer
        % Clear all data (CData and AlphaData) within a given layer.
        %
        % *Parameters*
        %
        % |slice|: ID of the target slice
        %
        % |layer|: ID of the target layer. Must be contained within the
        % specified slice.
        function clearLayer(obj, slice, layer)
            obj.Handles.slices.(['slice', num2str(slice)]).clearLayer(layer);
        end
    end
    
    methods (Access = private)
        %% checkSliceExists
        % Query the existance of a slice. Note that this method is
        % *private* and is not called externally to |Viewer|. Ideally,
        % there should not be an opportunity for the user to select a slice
        % that does not exist but if there is, the mechanism to handle this
        % should be a caught exception in the top-level calling scope.
        %
        % *Parameters*
        %
        % |id|: ID of the slice being queried for existance
        %
        % *Returns*
        %
        % |exixsts|: a |bool| representing if the slice exists
        function exists = checkSliceExists(obj, id)
            exists = isfield(obj.Handles.slices, ['slice' num2str(id)]);
        end
    end
end