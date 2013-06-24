%% PointLayer
% A |PointLayer| is used in the first stage of boundary determination. In
% the APEX/application, it is the mechanism for implementing clicking and
% erasing the initial version of the boundary. An |image| object with CData
% and AlphaData both set to the current state of the layer (the points
% which are selected) is used, as is a 2D matrix called the "stack", which
% records the order in which points have been clicked. This mechanism is
% important for the interpolation process, which is detailed within the
% documentation for <InterpolationLayer.html |InterpolationLayer|>.
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
classdef PointLayer < Layer
    %% Properties (Private)
    % *|stack|*: a 2D matrix containing the order of pixel locations
    % clicked. Newer clicks are are the bottom.
    properties (Access = private)
        stack
    end
    
    methods (Access = public)
        %% PointLayer (Constructor)
        % Instantiate an instance of |PointLayer|.
        function obj = PointLayer(parent)
            obj = obj@Layer(parent);
            obj.stack = [];
        end
        
        %% hasDataForCopy
        % See <Layer.html Layer documentation>.
        function has_data = hasDataForCopy(obj)
%             if obj.getStackSize() >= 1
%                 has_data = true;
%             else
%                 has_data = false;
%             end
            
            has_data = length(obj.stack);
        end
        
        %% getDataForCopy
        % See <Layer.html Layer documentation>.
        function data = getDataForCopy(obj)
            data = cell(1, 2);
            
            data{1} = obj.getStack();
            data{2} = obj.getCData();
        end
        
        %% setCopyData
        % See <Layer.html Layer documentation>.
        function setCopyData(obj, data)
            t = data{1};
            
            for i = 1 : length(t)
                t
                x = t(i, 1);
                y = t(i, 2);
                obj.addClickToStack(x, y);
                obj.paint(x, y);
            end
        end
       
        %% getStackSize
        % Query the number of points in the stack, or the number of total
        % point clicks.
        %
        % *Returns*
        %
        % |size|: number of clicks in the stack
        function size = getStackSize(obj)
            size = length(obj.stack);
        end
        
        %% getStack
        % Return the stack. Remember that MATLAB passes by reference until
        % a change is made to the object.
        %
        % *Returns*
        %
        % |s|: the stack for this |PointLayer|
        function s = getStack(obj)
            s = obj.stack;
        end
        
        %% setStack
        % Assign a new stack
        %
        % *Parameters*
        %
        % |s|: the new stack
        function setStack(obj, s)
            obj.stack = s;
        end
        
        %% indexOf
        % Return the position in the stack of coordinates (_x_, _y_), or -1
        % if they do not exist. Also returns -1 if the stack is empty.
        %
        % *Parameters*
        %
        % |x|: x coordinate
        %
        % |y|: y coordinate
        %
        % *Returns*
        %
        % |clicked|: position of the coordinate, or -1 if it does not exist
        function clicked = indexOf(obj, x, y)
            % Check if empty first
            if isempty(obj.stack)
                clicked = -1;
            else
                in = find(obj.stack(:, 1) == x & obj.stack(:, 2) == y);
            
                if isempty(in)
                    clicked = -1;
                else
                    clicked = in;
                end
            end
        end
        
        %% addClickToStack
        % Adds an (_x_, _y_) coordinate to the stack *unless* it does not
        % already exist. Multiples of clicks are not permitted.
        %
        % *Paramters*
        %
        % |x|: x coordinate
        %
        % |y|: y coordinate
        function addClickToStack(obj, x, y)
            [height width] = obj.getDimensions();
            if x < 1 || y < 1 || x > width || y > height
               throw(MException('PointLayerException:InvalidPaintCoordinate', '(%s, %s) is not a valid painting coordinate in this image as it is outside the image boundary', num2str(x), num2str(y)));
            end
            
            if obj.indexOf(x, y) == -1
                obj.stack(end + 1, :) = [x, y];
            end
        end
        
        %% removeClickFromStack
        % Removes an (_x_, _y_) from the stack.
        %
        % *Paramters*
        %
        % |x|: x coordinate
        %
        % |y|: y coordinate
        function removeClickFromStack(obj, x, y)
            position = obj.indexOf(x, y);
            
            if position == -1
                % The point doesn't exist, so can't remove it
                return
            end
            
            obj.stack(position, :) = [];
        end
        
        %% paint
        % Add a point to the CData and update the AlphaData accordingly
        %
        % *Paramters*
        %
        % |x|: x coordinate
        %
        % |y|: y coordinate
        function paint(obj, x, y)
            % Bounds checking first. Need to ensure (|x|, |y|) is within
            % acceptable bounds because there can slides of different
            % dimensionality
            [height width] = obj.getDimensions();
            if x < 1 || y < 1 || x > width || y > height
               throw(MException('PointLayerException:InvalidPaintCoordinate', '(%s, %s) is not a valid painting coordinate in this image as it is outside the image boundary', num2str(x), num2str(y)));
            end
            
            % Pain the data
            img = obj.getCData();
            img(y, x) = 1;
            obj.setCData(img);
            obj.setAlphaData(img);
        end
        
        %% unpaint
        % Remove a point to the CData and update the AlphaData accordingly
        %
        % *Paramters*
        %
        % |x|: x coordinate
        %
        % |y|: y coordinate
        function unpaint(obj, x, y)
            img = obj.getCData();
            img(y, x) = 0;
            obj.setCData(img);
            obj.setAlphaData(img);
        end
        
        %% undoLastPoint
        % Unpaints and removes the newest click in the stack
        function undoLastPoint(obj)
            x = obj.stack(end, 1);
            y = obj.stack(end, 2);
            
            obj.unpaint(x, y);
            obj.removeClickFromStack(x, y);
        end
        
        %% clear
        % Clear all CData, AlphaData and the stack.
        function clear(obj)
            for i = 1 : length(obj.stack)
                obj.undoLastPoint();    
            end
            
            % Add zero data, otherwise the image will have 0 size, meaning
            % it cannot be clicked
            obj.setCData(zeros(512));
            obj.setAlphaData(zeros(512));
        end
    end
end