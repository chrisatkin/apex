%% InterpolationTechnique
% An |InterpolationTechnique| represents a given
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
classdef InterpolationTechnique
    enumeration
        %% Interpolation Techniques
        % *Poly2Mask*: use the |poly2mask| function 
        Poly2Mask
    end
end