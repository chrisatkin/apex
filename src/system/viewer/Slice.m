%% Slice
% A |Slice| class is the middle tier of abstraction within the APEX/F
% graphical stack. It is an abstraction for handling a single CT scan and
% associated actions, such as creating an interpolation. In the same way
% that |Viewer| provides high-level operations for all |Slice| objects, a
% |Slice| provides operations that affect multiple |Layer| objects. Like
% |Viewer|, the majority of the functionality provided by |Slice| is
% routing to the appropriate layer.
%
% A |Slice| contains multiple |Layer| objects, which are stored in a
% |struct()| identified by |obj.Layers|. Unlike |Viewer|, a |Slice| does
% not create any graphical objects without assistance.
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
%%
% <<general-arch.png>>
%
classdef Slice < handle
    %% Properties (Private)
    % *|parent|*: an |axes| object into which contained |Layer| objects are
    % injected
    %
    % *|id|*: a unique numeric identifier for the |Slice|
    %
    % *|Layers|*: a |struct()| containing |Layer| objects. Note that unlike
    % in |Viewer|, because |Layer| objects have a string identifier (a
    % _name_), dynamic property access can be used
    %
    % *|visible*|: visibility of the |Slice|. Similar to |image| handle
    % visibility settings
    properties (Access = private)
        parent
        id
        Layers
        visible
    end
    
    methods (Access = public)
        %% Slice (constructor)
        % Instantiate an instance of |Slice|. No graphical elements are
        % created within |Slice|.
        %
        % *Parameters*
        %
        % |parent|: |axes| handle into which |Layer| objects will be
        % injected
        %
        % |id|: unique numeric identifier of the slice
        function obj = Slice(parent, id)
            obj = obj@handle();
            obj.parent = parent;
            obj.id = id;
            obj.Layers = struct();
            obj.visible = false;
        end
        
        %% assignLayer
        % Create a new |Layer| and add it to the current |Slice|. The order
        % of creation *is* important, and |Layer| objects cannot be
        % reordered after creation. See the documentation for <Layer.html
        % Layers> for further details on the |Layer| object and its
        % subclasses.
        %
        % *Parameters*
        %
        % |kind|: the type of |Layer| to be created. Must be one of
        %
        % * |Bitmap|
        % * |Interpolation|
        % * |Point|
        %
        % Otherwise a |SliceException| is thrown.
        %
        % |name|: unique |char| identifier for the created |Layer|.
        function assignLayer(obj, kind, name)
            switch kind
                case 'Bitmap'
                    obj.Layers.(name) = BitmapLayer(obj.parent);
                
                case 'Interpolation'
                    obj.Layers.(name) = InterpolationLayer(obj.parent);
                    
                case 'Point'
                    obj.Layers.(name) = PointLayer(obj.parent);
                    
                otherwise
                    throw(MException('SliceException:InvalidLayerKind:assignLayer', '%s is not a valid layer type', kind));
            end
        end
        
        %% setLayerCData
        % Sets the CData for a given |Layer|. Follows similar rules to
        % |image| handle CData properties.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |data|: 2-dimensional (|n*m|) data to be applied
        function setLayerCData(obj, layer, data)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:setLayerCData', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setCData(data);
        end
        
        %% setLayerAlphaData
        % Sets the AlphaData for a given |Layer|. Follows similar rules to
        % |image| handle AlphaData properties.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |data| 2-dimensional (|n*m|) to be applied. Follows normal rules
        % for AlphaData. Should be a binary image
        function setLayerAlphaData(obj, layer, data)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:setLayerAlphaData', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setAlphaData(data);
        end
        
        %% setLayerVisibility
        % Set a given |Layer| s visibility. Note that the containing
        % |Slice| must also be visible. Details of the possible states for
        % |Layer| objects are found within the <Layer.html Layer
        % documentation>. Normal rules for |image| handle visibilities are
        % observed.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |visibility|: new visibility of the |Layer|. Possible values are
        % |on| and |off|.
        function setLayerVisibility(obj, layer, visibility)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:setLayerVisibility', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setVisibility(visibility);
        end
        
        %% getLayerVisibility
        % Query a given |Layer| objects visibility.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        function visible = getLayerVisibility(obj, layer)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:setLayerAlphaData', '%s is not a valid layer identifier', layer));
            end
            
            visible = obj.Layers.(layer).getVisibility();
        end
        
        %% addLayerButtonDownListener
        % Assign a callback to execute upon mouse *click* (_not_
        % dragging!). The callback will execute in the scope of the |Layer|
        % object. Further documentation on this mechanism can be found
        % within the <Layer.html Layer documentation>.
        % 
        % Compare with <Viewer.html Viewer.addSliceButtonDownListener>.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addLayerButtonDownListener(obj, layer, fcn)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:addLayerButtonDownListener', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setButtonDownCallback(fcn);
        end
        
        %% addLayerButtonUpListener
        % Similar to |Slice.addLayerButtonDownListener|, except fires upon
        % mouse _up_.
        % 
        % Compare with <Viewer.html Viewer.addSliceButtonUpListener>.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addLayerButtonUpListener(obj, layer, fcn)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:addLayerButtonUpListener', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setButtonUpCallback(fcn);
        end
        
        %% addLayerButtonMotionListener
        % Similar to |Slice.addLayerButtonDownListener|, except fires upon
        % mouse drag. *Note that only one Motion Listener should be attached at any
        % given time. This is due to a limiation within MATLABs listener
        % architecture  whereby a listener is attached to a |figure| and
        % not an |image|, like in Button Listeners*.
        %
        % Compare with <Viewer.html Viewer.addSliceButtonMotionListener>.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function addLayerButtonMotionListener(obj, layer, fcn)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:addLayerButtonMotionListener', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setMouseMotionCallback(fcn);
        end
        
        %% removeLayerButtonMotionListener
        % Removes a Motion Listener from the specified layer.
        %
        % Compare with <Viewer.html Viewer.removeSliceButtonMotionListner>.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        function removeLayerButtonMotionListener(obj, layer)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:removeLayerButtonMotionListener', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).removeMouseMotionCallback();
        end
        
        %% dilateLayerSelection
        % Perform the dilation morphological operation upon an
        % |InterpolationLayer|. The dilation uses a disk kernel.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |by|: pixel value to dilate by. Note that 1 is added to this
        % value in order to gain an accurate dilation amount.
        function dilateLayerSelection(obj, layer, by)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerName:dilateLayerSelection', '%s is not a valid layer identifier', layer));
            end
            
            if ~ strcmp(class(obj.Layers.(layer)), 'InterpolationLayer')
                throw(MException('SliceException:InvalidLayerKind:dilateLayerSelection', '%s is not an InterpolationLayer', layer));
            end
            
            obj.Layers.(layer).dilate(by);
            obj.Layers.(layer).drawInterpolation(0.5);
        end
        
        %% erodeLayerSelection
        % Perform the erosion morphological operation upon an
        % |InterpolationLayer|. The erosion uses a disk kernel.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |by|: pixel value to erode by. Note that 1 is added to this
        % value in order to gain an accurate erosion amount.
        function erodeLayerSelection(obj, layer, by)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerKind:erodeLayerException', '%s is not a valid layer identifier', layer));
            end
            
            if ~ strcmp(class(obj.Layers.(layer)), 'InterpolationLayer')
                throw(MException('SliceException:InvalidLayerKind:erodeLayerSelection', '%s is not an InterpolationLayer', layer));
            end
            
            obj.Layers.(layer).erode(by);
            obj.Layers.(layer).drawInterpolation(0.5);
        end
        
        %% setVisibility
        % Set the visibility of the |Slice| layer. See <Layer.html Layer
        % documentation> for information regarding visibility and activity.
        %
        % *Parameters*
        %
        % |visibility|: |char| identifier, |on| or |off| (otherwise a
        % |SliceException| is thrown.
        function setVisible(obj, visibility)
            fh = fieldnames(obj.Layers);
            
            if strcmp(visibility, 'on')
                obj.visible = true;
                for i = 1 : length(fh)
                    if obj.Layers.(fh{i}).isActive()
                        obj.Layers.(fh{i}).setVisibility('on');
                    else
                        obj.Layers.(fh{i}).setVisibility('off');
                    end
                end
            elseif strcmp(visibility, 'off')
                obj.visible = false;
                for i = 1 : length(fh)
                    obj.Layers.(fh{i}).setVisibility('off');
                end
            else
                throw(MException('SliceException:InvalidVisibilityOption:setVisible', '%s is not a valid visibility option', visibility));
            end
        end
        
        %% setLayerActive
        % Set a |Layer| object to active. See <Layer.html Layer
        % documentation> for information regarding visibility and activity.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |active|: activity (as a |bool|) of the target |Layer|
        function setLayerActive(obj, layer, active)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerKind:erodeLayerException', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setActive(active);
        end
        
        %% interpolateFromPointLayer
        % Perform an interpolation operation on a |target| layer from a
        % |source| layer. The |source| layer is a fully-fledged |Layer|
        % object, not a reference.
        %
        % *Parameters*
        %
        % |source|: the source layer. Must be a |PointLayer|
        %
        % |target|: the target layer. Must be an |InterpolationLayer|
        function interpolateFromPointLayer(obj, source, target)
            fprintf('Stack size: %i\n', obj.Layers.(source).getStackSize());
            
            if obj.Layers.(source).getStackSize() <= 2
                throw(MException('SliceException:MinimumPointCountViolated:interpolateFromPointLayer', 'Cannot interpolate with fewer than 3 points'));
            end
            
            disp('Interpolating...');
            obj.Layers.(target).importStack(obj.Layers.(source).getStack(), InterpolationTechnique.Poly2Mask);
            obj.Layers.(target).drawInterpolation(0.5);
        end
        
        %% doAction
        % Perform an action (through a function identifier or anonymous
        % function) upon each |Layer| within the |Slice|, with lexical
        % scope of |Layer|.
        %
        % See <Viewer.html Viewer.each>.
        %
        % *Parameters*
        %
        % |slice_id|: slice ID to pass to the callback
        %
        % |fcn|: function handle or anonymous function to be executed in
        % each |Layer| object
        function doAction(obj, slice_id, fcn)          
            fh = fieldnames(obj.Layers);
            for i = 1 : length(fh)
                fcn(slice_id, obj.Layers.(fh{i}));
            end
        end
        
        %% setContrastEnabled
        % Enable the contrast viewer on a |BitmapLayer|.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |enabled|: |bool| representing the status of the contrast viewer
        function setContrastEnabled(obj, layer, enabled)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerKind:setConstrastEnabled', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setContrastEnabled(enabled);
        end
        
        %% setZoomEnabled
        % Enable the high-powered zoom on a |BitmapLayer|.
        %
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        %
        % |enabled|: |bool| representing state of high-powered zoom
        function setZoomEnabled(obj, layer, enabled)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerKind:setZoomEnabled', '%s is not a valid layer identifier', layer));
            end
            
            obj.Layers.(layer).setZoomEnabled(enabled);
        end
        
        %% copyFromSlice
        % Perform the copy action. Details of the copy-paste mechanism can
        % be found within the <Viewer.html Viewer documentation>.
        %
        % *Parameters*
        %
        % |from_slice|: |Layer| object from which to perform the copy. The
        % current |Slice| is the target |Layer|
        %
        % |to_copy|: |char| cell array describing which |Layer| objects
        % should be copied
        function copyFromSlice(obj, from_slice, to_copy)
            % We're going to use the Slice.do_action (the implementation
            % behind Viewer.each) to do the heavy lifting, so we need a
            % function to pass to it.
            function copyAction(id, object)
                % to_copy is a cell array of the layer types to copy (e.g.,
                % {'Point', 'Interpolation'} so we need to ensure the
                % current layer type ( class(object) ) is contained within
                % to_copy.
                if find(ismember(to_copy, strrep(char(class(object)), 'Layer', '')) == 1)
                    if object.hasDataForCopy()
                        obj.copyData(object.getDataForCopy(), class(object));
                    end
                end
            end
            
            from_slice.doAction(from_slice.id, @copyAction);
        end
        
        %% undoLastClick
        % Undo the last click in the specified |PointLayer|. This can be
        % called |n| times, where |n| is the number of points within the
        % layer.
        %
        % *Parameters*
        %
        % |layer|: the layer to undo the click on. Must be a |PointLayer|
        % identifier, otherwise a |SliceException| is thrown.
        function undoLastClick(obj, layer)
            if ~ obj.checkLayerExists(layer)
                throw(MException('SliceException:InvalidLayerKind:undoLastPoint', '%s is not a valid layer identifier', layer));
            end
            
            % Ensure |layer| is a PointLayer, otherwise throw a
            % |SliceException|
            if ~ strcmp(class(obj.Layers.(layer)), 'PointLayer')
                throw(MException('SliceException:NotPointLayer', '%s is not a PointLayer', layer));
            end
            
            obj.Layers.(layer).undoLastPoint();
        end
        
        %% clearLayer
        % Clear all data (CData and AlphaData) within a given layer.
        % *Parameters*
        %
        % |layer|: unique |char| identifier of the target |Layer| object
        function clearLayer(obj, layer)
            obj.Layers.(layer).clear();
            obj.Layers.interpolation.clear();
            
            obj.Layers.interpolation.setVisibility('off');
            obj.Layers.interpolation.setActive(false);
            
            obj.Layers.(layer).setVisibility('on');
            obj.Layers.(layer).setActive(true);
        end
    end
    
    methods (Access = private)
        %% checkLayerExists
        % Query the existance of a |Layer| object identifier
        %
        % *Parameters*
        %
        % |name|: the ID of the |Layer| being queried
        %
        % *Returns*
        %
        % |exists|: a |bool| representing |Layer| existance
        function exists = checkLayerExists(obj, name)
            exists = isfield(obj.Layers, name);
        end
        
        %% copyData
        % Implement the copy action and set appropraite visibilities after.
        %
        % *Parameters*
        %
        % |data|: copydata
        %
        % |layertype|: |char| containing the type of the |Layer|
        function copyData(obj, data, layertype)
            switch layertype
                case 'PointLayer'
                    obj.Layers.points.setCopyData(data);
                    obj.Layers.points.setVisibility('on');
                    obj.Layers.points.setActive(true);
                case 'InterpolationLayer'
                    obj.Layers.interpolation.setCopyData(data);
                    obj.Layers.interpolation.setVisibility('on');
                    obj.Layers.interpolation.setActive(true);
                    obj.Layers.points.setVisibility('off');
                    obj.Layers.points.setActive(false);
                otherwise
                    throw(MException('SliceException:InvalidCopyLayerType', '%s is not a valid copy target', layertype));
            end
        end
    end
end