%% InterpolationLayer
% An |InterpolationLayer| supports morphological operations upon it, such
% as dilation and erosion. It is used to display a contigious area,
% interpolated from a <PointLayer.html |PointLayer|>.
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
% * <InterpolationTechnique.html InterpolationTechnique>
% 
%%
% <<general-arch.png>>
%
classdef InterpolationLayer < Layer
    %% Properties (Private)
    % *|interpolation|*: the binary mask produced by the interpolation
    % method
    %
    % *|boundary|*: trace of the interpolation . Uses 8-connected with a
    % starting direction of sw (see |bwtraceboundary|)
    %
    % *|stack|*: stack of points (see <PointLayer.html |PointLayer|> for
    % more information)
    %
    % *|structuring_shape|*: kernel shape used for dilation and erosion
    properties (Access = private)
        interpolation
        boundary
        stack
        structuring_shape
    end
    
    methods (Access = public)
        %% InterpolationLayer (Constructor)
        % Instantantiate an instance of |InterpolationLayer|.
        function obj = InterpolationLayer(parent)
            obj = obj@Layer(parent);
            obj.structuring_shape = 'disk';
        end
        
        %% hasDataForCopy (Abstract)
        % See <Layer.html Layer documentation>.
        function has_data = hasDataForCopy(obj)
            if isempty(obj.stack)
                has_data = false;
            else
                has_data = true;
            end
        end
        
        %% getDataForCopy (Abstract)
        % See <Layer.html Layer documentation>.
        function data = getDataForCopy(obj)
            data = cell(1, 1);
            data{1} = obj.stack;
        end
        
        %% setCopyData (Abstract)
        % See <Layer.html Layer documentation>.
        function setCopyData(obj, data)
            obj.importStack(data{1}, 512, 512);
        end
        
        %% importStack
        % Create a new interpolation from a stack and draw it to the
        % CData/AlphaData. Creating an interpolation uses |poly2mask|.
        %
        % *Parameters*
        %
        % |stack|: the stack to interpolate from. Point order is taken into
        % consideration.
        %
        % |width| and |height|: width and height of the interpolation mask
        function importStack(obj, stack, technique)            
            % Grab the stack
            obj.stack = stack;
            
            % Interpolate
            obj.setInterpolation(obj.interpolate(technique));
            
            % Draw the interpolation
            obj.drawInterpolation(0.5);
            obj.setVisibility('on');
        end
        
        %% getBoundary
        % Trace the boundary of the interpolation from the first nonzero
        % pixel value. Uses a sw default direction and 8-connections.
        function boundary = getBoundary(obj)
            [row col] = find(obj.interpolation, 1, 'first');            
            boundary = bwtraceboundary(obj.interpolation, [row col], 'sw');
        end
        
        %% setInterpolation
        % Assign a new interpolation.
        %
        % *Parameters*
        %
        % |interpolation|: the new interpolation. Must be a (_n_*_m_)
        % binary matrix.
        function setInterpolation(obj, interpolation)
            obj.interpolation = interpolation;
        end
        
        %% getInterpolation
        % Get the current interpolation.
        %
        % *Returns*
        %
        % |i|: the current interpolation
        function i = getInterpolation(obj)
            i = obj.interpolation;
        end
        
        %% drawInterpolation
        % Assign the current interpolation (a binary mask) to CData and
        % AlphaData
        function drawInterpolation(obj, opacity)
            obj.setCData(obj.interpolation);
            obj.setAlphaData(obj.interpolation .* opacity);
        end
        
        %% toggleInterpolationPixel
        % To allow for interpolation editing, a toggle is fired when the
        % mouse is clicked.
        function toggleInterpolationPixel(obj, x, y)
            if obj.interpolation(y, x) == 1
                obj.interpolation(y, x) = 0;
            else
                obj.interpolation(y, x) = 1;
            end
        end
        
        %% setStructuringShape
        % Assign the structuring kernel for dilation/erosion. See |strel|
        % for details.
        %
        % *Parameters*
        %
        % |shape|: |char| determining the structuring shape. See |strel|.
        function setStructuringShape(obj, shape)
            if ~ isa(shape, 'char')
                throw(MException('LayerException:InvalidStructuringElementIdentifier:setStructuringShape', '%s is not a valid structuring element', shape));
            end
            
            obj.structuring_shape = shape;
        end
        
        %% dilate
        % Perform the dilation morphological operation. Uses a disk kernel.
        %
        % *Parameters*
        %
        % |by|: pixel value to dilate by. Note that 1 is added to this
        % value in order to gain an accurate dilation amount.
        function dilate(obj, by)
            % Set the new interpolation
%             obj.interpolation = imdilate(obj.interpolation, ones(by + 2));
            obj.interpolation = imdilate(obj.interpolation, strel('disk', by + 1));
        end
        
        %% erode
        % Perform the erosion morphological operation. Uses a disk kernel.
        %
        % *Parameters*
        %
        % |by|: pixel value to erode by. Note that 1 is added to this
        % value in order to gain an accurate erosion amount.
        function erode(obj, by)
            obj.interpolation = imerode(obj.interpolation, strel('disk', by + 1));
        end
        
        %% clear
        % Clear all CData, AlphaData, the interpolation and the stack.
        function clear(obj)
            obj.setCData(zeros(512));
            obj.setAlphaData(zeros(512));
            obj.stack = [];
            obj.interpolation = [];
        end
    end
    
    methods (Access = private)
       %% interpolate
       % Implements the interpolation function for a number of
       % interpolation techniques, including Poly2Mask
	   %
	   % *Parameters*
	   %
	   % |technique|: |InterpolationTechnique| is a custom type (enum)
	   % specifying the technique to use. The default techniques are:
	   %
	   % * |Poly2Mask2|: use the MATLAB |poly2mask| function. This has the
	   % advantage that 
	   %
	   % *Returns*
	   %
	   %
       function i = interpolate(obj, technique)
		   fprintf('Interpolation technique: %s\n', char(technique));
		   
           switch technique
               case InterpolationTechnique.Poly2Mask
%                    [width height] = obj.getDimensions();
                   i = poly2mask(obj.stack(:, 1), obj.stack(:, 2), 512, 512);
               
               otherwise
                   throw(MException());
           end
       end
    end
end