%% Layer
% A |Layer| is the lowest level of abstraction within the APEX/F graphical
% stack. A Layer is a combination of an abstraction of an |image| handle
% and operations that are performed upon layers.
%
% There are three kinds of Layer:
%
% * *|BitmapLayer|*, for containing bitmapped images. These are used to
% hold the underlying CT scan images
% * *|PointLayer|*, for implementing the first step in the boundary
% determination
% * *|InterpolationLayer|*, which implements dilation and erosion, as well
% as maximum internal rectangle determination algorithm.
%
% *Layer states: Visibility and Activity*
%
% There are two important states for |Layer| objects, visibility and
% activity. *Visibility* refers to whether or not the layer is visible
% within the figure, assuming that the containing |Slice| is visible.
% *Activity* is a related concept, determining whether or not the |Layer|
% _should_ be visible. This is used to ensure different |Layer| objects
% retain correct visibilities whilst setting visibility of |Slice| objects.
% Visible layers are active, but active layers are not nessecarily visible
% - they will not be visible if their |Slice| container is not visible.
%
% Activity can be thought of as a historical record about the visibility of
% a |Layer| whilst the containing |Slice| is not visible.
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
classdef Layer < handle
    %% Properties (Private)
    % *|parent|*: the parent |axes| handle into which an |image| handle
    % should be created
    %
    % *|image|*: |image| handle for displaying data and attaching events to
    %
    % *|active|*: |bool| represnting the current activity of the layer.
    % Note that visibility is determined using |get(obj.image,
    % 'Visible')| rather than a |bool|
    %
    % *|contrast|*: |bool| representing whether a constrast tool is
    % displayed for this layer
    %
    % *|contrast_handle|*: handle to the contrast viewer, if displayed
    %
    % *|zoom|*: |bool| representing whether a high-powered zoom is
    % displayed for this layer
    %
    % *|zoom_handle|*: handle to the high-power zoom, if displayed
    %
    % *|callbacks|*: callback objects
    properties (Access = private)
        parent
        image
        active
        contrast
        contrast_handle
        zoom
        zoom_handle
        callbacks
    end
    
    methods (Abstract)
        %% hasDataForCopy (abstract)
        % Abstract methods that determines if the current slide has data
        % available for copying. See the <Viewer.html Viewer documentation>
        % for a general overview.
        % 
        % *Returns*
        %
        % |has_data|: |bool| determining if the |Layer| has data suitable
        % for copying
        has_data = hasDataForCopy(obj);
        
        %% getDataForCopy (abstract)
        % Abstract method for getting data to be copied. See the
        % <Viewer.html Viewer documentation> for a general overview.
        %
        % *Returns*
        %
        % |data|: a |cell array| of data to be copied. Target |Layer| can
        % "handle" the cell array appropriately.
        data = getDataForCopy(obj);
        
        %% setCopyData (abstract)
        % Assign data from a copy operation. See the <Viewer.html Viewer
        % documentation> for a general overview.
        %
        % *Parameters*
        %
        % |data|: the data to be copied
        setCopyData(obj, data);
    end
    
    methods (Access = public)
        %% Layer (constuctor)
        % Instantiate an instance of |Layer|, and creates an |image| handle
        % into which data is inserted.
        %
        % *Parameters*
        %
        % |parent|: the parent |axes| of the |image| object
        function obj = Layer(parent)
            obj.parent = parent;
            obj.image = imagesc('Parent', obj.parent, 'Visible', 'off');
            obj.active = false;
            obj.contrast = false;
            obj.zoom = false;
            obj.contrast_handle = false;
            obj.zoom_handle = false;
            obj.callbacks = cell(1, 3);
        end
        
        %% setVisibility
        % Set the visibility of a |Layer|. Follows the same rules as an
        % |image| handle.
        %
        % *Parameters*
        %
        % |visibility|: |char| setting for the |Visible| property of the
        % |image| object
        function setVisibility(obj, visibility)
            fprintf('Setting %s to %s \n', class(obj), visibility)
            set(obj.image, 'Visible', visibility);
        end
        
        %% getVisibility
        % Determine the visibility of the current |Layer|.
        %
        % *Returns*
        %
        % |visibility|: |char| represnting the visibility of the |Layer|.
        % Either |on| or |off|.
        function visibility = getVisibility(obj)
            visibility = get(obj.image, 'Visible');
        end
        
        %% getCData
        % Return the current CData of the |Layer|.
        %
        % *Returns*
        %
        % |data|: current CData of the |Layer|
        function data = getCData(obj)
            data = get(obj.image, 'CData');
		end		
        
        %% getDimensions
        % Return the |x|*|y| dimensions of the Layer
        %
        % *Returns*
        %
        % |height|: number of pixels in the |y| dimension
        %
        % |width|: number of pixels in the |x| dimension
        function [width height] = getDimensions(obj)
            [width height] = size(obj.getCData());
			fprintf('%s dimensions: (%i, %i)', char(class(obj)), width, height)
        end
        
        %% setCData
        % Assign CData for the layer. Follows normal rules for |image|
        % CData. *Note that only 2-dimensional data is supported. RGB data
        % is unsupported.*
        %
        % *Parameters*
        %
        % |data|: 2-dimensional data of CData to be assigned to the
        % |image|.
        function setCData(obj, data)
            set(obj.image, 'CData', data);
        end
        
        %% setAlphaData
        % Assign AlphaData for the layer. Follows normal rules for image|
        % AlphaData.
        %
        % *Parameters*
        %
        % |data|: 2-dimensional data to be assigned to AlphaData of the
        % |image|.
        function setAlphaData(obj, data)
            set(obj.image, 'AlphaData', data);
        end
        
        %% setActive
        % Assign the |Layer| s activity.
        %
        % *Parameters*
        %
        % |active|: a |bool| for the activity
        function setActive(obj, active)
            obj.active = active;
        end
        
        %% isActive
        % Query the activity of the |Layer|.
        %
        % *Returns*
        %
        % |active|: a |bool| represnting the activity of the |Layer|
        function active = isActive(obj)
            active = obj.active;
        end
        
        %% setContrastEnabled
        % Enable or disable the contrast tool for this |Layer|.
        %
        % *Parameters*
        %
        % |enabled|: |char| (either |on| or |off|) determining the visibility of
        % the contrast tool.
        function setContrastEnabled(obj, enabled)
            if strcmp(enabled, 'on')
                obj.openContrast();
            elseif strcmp(enabled, 'off')
                obj.closeContrast();
            else
                throw(MException('LayerException:InvalidContrastSetting:setContrastEnabled', '%s is not a valid contrast option', enabled));
            end
        end
        
        %% setZoomEnabled
        % Enable or disable the high-powered zoom tool for this |Layer|.
        %
        % *Parameters*
        %
        % |enalbed|: |char| (either |on| or |off|) determining the
        % visibility of the high-powered zoom tool.
        function setZoomEnabled(obj, enabled)
            if strcmp(enabled, 'on')
                obj.openZoom();
            elseif strcmp(enabled, 'off')
                obj.closeZoom();
            else
                throw(MException('LayerException:InvalidContrastSetting:setZoomEnabled', '%s is not a valid zoom option', enabled));
            end
        end
        
        %% setButtonDownCallback
        % Assign a callback to execute upon mouse click within the |image|
        % object. Executes in the scope of the |Layer| object.
        %
        % *Parameters*
        %
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function setButtonDownCallback(obj, fcn)
            function LayerButtonDownPrototype(hObject, eventdata)            
                points = get(ancestor(hObject, 'axes'), 'CurrentPoint');
                x = round(points(1, 1));
                y = round(points(1, 2));
                
                fcn(x, y, obj);
            end
            
            set(obj.image, 'ButtonDownFcn', @LayerButtonDownPrototype);
        end
        
        %% setButtonUpCallback
        % Similar to |Layer.setButtonDownCallback| except fires upon mouse
        % _up_.
        %
        % *Parameters*
        % |fcn|: function identifier or anonymous function to attach to the
        % event
        function setButtonUpCallback(obj, fcn)
            function LayerButtonUpPrototype(hObject, eventdata)
                points = get(ancestor(hObject, 'axes'), 'CurrentPoint');
                x = round(points(1, 1));
                y = round(points(1, 2));
                
                fcn(x, y, obj);
            end
            
            set(obj.image, 'ButtonUpFcn', @LayerButtonUpPrototype);
        end
        
        %% setMouseMotionCallback
        % Similar to |Layer.setMouseMotionCallback|, except fires upon
        % mouse drag. *Note that the callback _must_ be removed before
        % another one is attached to another |Layer| object, and must be
        % attached to the currently visible |Layer|.*
        %
        % *Parameters*
        %
        % |fcn|: function handle or anonymous function representing action
        % to be fired when the mouse is dragged
        function setMouseMotionCallback(obj, fcn)
            down = false;
            function FigureDown(hObject, eventdata)
                down = true;
            end
            
            function FigureUp(hObject, eventdata)
                down = false;
            end
            
            function FigureMotion(hObject, eventdata)
                if down
                    points = get(ancestor(obj.parent, 'axes'), 'CurrentPoint');
                    x = round(points(1, 1));
                    y = round(points(1, 2));
                    
%                     fprintf('This is motion on %i\n', slice_id)
                    fcn(x, y, obj);
                end
            end
            
            obj.callbacks{1} = iptaddcallback(ancestor(obj.parent, 'figure'), 'WindowButtonDownFcn', @FigureDown);
            obj.callbacks{2} = iptaddcallback(ancestor(obj.parent, 'figure'), 'WindowButtonUpFcn', @FigureUp);
            obj.callbacks{3} = iptaddcallback(ancestor(obj.parent, 'figure'), 'WindowButtonMotionFcn', @FigureMotion);
        end
        
        %% removeMouseMotionCallback
        % Remove the attached Motion Listener on the |image|.
        function removeMouseMotionCallback(obj)
            iptremovecallback(ancestor(obj.parent, 'figure'), 'WindowButtonDownFcn', obj.callbacks{1});
            iptremovecallback(ancestor(obj.parent, 'figure'), 'WindowButtonUpFcn', obj.callbacks{2});
            iptremovecallback(ancestor(obj.parent, 'figure'), 'WindowButtonMotionFcn', obj.callbacks{3});
        end
        
        %% removeButtonDownCallback
        % Remove the Button Down listener.
        function removeButtonDownCallback(obj)
            iptremovecallback(obj.image, 'ButtonDownFcn', @LayerButtonDownPrototype);
        end
        
        %% removeButtonUpCallback
        % Remove the Button Up listener.
        function removeButtonUpCallback(obj)
            iptremovecallback(obj.image, 'ButtonUpFcn', @LayerButtonUpPrototype);
        end
    end
    
    methods (Access = private)
       
        %% openConstrast (Private)
        % Open the contrast tool for the |image|
        function openContrast(obj)
            obj.contrast = true;
            obj.contrast_handle = imcontrast(obj.image);
        end
        
        %% closeContrast (Private)
        % Close the contrast tool for |image|
        function closeContrast(obj)
            obj.contrast = false;
            delete(obj.contrast_handle);
            obj.contrast_handle = false;
        end
        
        %% openZoom (Private)
        % Open high-powered zoom tool for |image|
        function openZoom(obj)
            obj.zoom = true;
            obj.zoom_handle = impixelregion(obj.image);
        end
        
        %% closeZoom (Private)
        % Close high-powered zoom tool for |image
        function closeZoom(obj)
            obj.zoom = false;
            delete(obj.zoom_handle);
            obj.zoom_handle = false;
        end
    end
end