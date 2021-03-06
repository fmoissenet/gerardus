function scimat = scimat_downsample(scimat)
% SCIMAT_DOWNSAMPLE Downsample scimat image by x2.
%
% It first applies a gaussian filter in order to smooth the image
% and the proceeds to sample half of the original image. 
% 
% DISCLAIMER: Method has NOT been verified for 3D case. 
%    
% Function SCIMAT_DOWNSAMPLE() takes a scimat struct as an input. It then
% proceeds to smooth the image in the scimat struct by applying a gaussian
% filter in either 2 or 3 dimensions, depending on the scimat struct
% dimensions. Once smoothed, the spacial locations of the voxels is
% recalcuated at half the sample frequency of the original image.
%
% SCIMAT = SCIMAT_DOWNSAMPLE(SCIMAT)
% 
% SCIMAT (input) and SCIMAT (output) are both structs used in Gerardus to 
% store 2D, 3D or 3D+t images and axis metainformation. For more
% information, see "help scimat".
%
% Example: 
%  
% scimatout = SCIMAT_DOWNSAMPLE(scimatin)
% 
% scimatin = 
% 
%       axis: [3x1 struct]
%       data: [128x128 double]
%     rotmat: [3x3 double]
%
% scimatout = 
% 
%       axis: [3x1 struct]
%       data: [64x64 double]
%     rotmat: [3x3 double]
%
% See also: scimat_resize3, scimat_resample.

% Authors: Benjamin Villard <b.016434@gmail.com>,
% Vicente Grau  <vicente.grau@eng.ox.ac.uk>
% Christopher Kelly <christopher.kelly28@googlemail.com>
% Copyright © 2015-2016 University of Oxford
% Version: 0.3.2
% 
% University of Oxford means the Chancellor, Masters and Scholars of
% the University of Oxford, having an administrative office at
% Wellington Square, Oxford OX1 2JD, UK. 
%
% This file is part of Gerardus.
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. The offer of this
% program under the terms of the License is subject to the License
% being interpreted in accordance with English Law and subject to any
% action against the University of Oxford being under the jurisdiction
% of the English Courts.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


% check arguments
narginchk(1, 1);
nargoutchk(0, 1);

% defaults
origsze(1) = size(scimat.data,1);
origsze(2) = size(scimat.data,2);
origsze(3) = size(scimat.data,3);
origspc(1) = scimat.axis(1).spacing;
origspc(2) = scimat.axis(2).spacing;
origspc(3) = scimat.axis(3).spacing;
% Calculate coordinate plane 
[coords(:,:,1),coords(:,:,2),coords(:,:,3)] = scimat_ndgrid(scimat);

if(ndims(scimat) == 3)
    
    % Create Gaussian filter
    gfilt = zeros(1,1,5);   %Three-dim kernel
    gfilt(1,1,:) = [1 4 6 4 1]./16;
    
    % Apply filter to image in all three directions
    scimat = convn(convn(convn(scimat,shiftdim(gfilt,2),'same'),shiftdim(gfilt,1),'same'),gfilt,'same');
    
    % Recalculate image
    scimatout = scimat(1:2:size(scimat,1),1:2:size(scimat,2),1:2:size(scimat,3));
     
    % Update scimat
    scimat.data = scimatout;
    
    % Recalculate size of image
    scimat.axis(1).size = origsze(1);
    scimat.axis(2).size = origsze(2);
    scimat.axis(3).size = origsze(3);
    
    % Update spacing
    scimat.axis(1).spacing = origspc(1)*2;
    scimat.axis(2).spacing = origspc(2)*2;
    scimat.axis(3).spacing = origspc(3)*2;

elseif(ndims(scimat.data) == 2)
    
    % Create Gaussian filter
    gfilt=[1 4 6 4 1]./16;
    
    % Apply filter to image in both directions
    scimat.data = convn(scimat.data,gfilt,'same');
    scimat.data = convn(scimat.data,gfilt','same');        
    
    % Recalculate size of image
    size_out = [floor(origsze(1)/2) floor(origsze(2)/2)];
    
    % Update scimat
    scimat.axis(1).size = size_out(1);
    scimat.axis(2).size = size_out(2);
    
    % Update spacing
    scimat.axis(1).spacing = (origspc(1))*2;
    scimat.axis(2).spacing = (origspc(2))*2;
	
    
    % Recalculate image
    [x1,y1] = ndgrid(0:(origsze(1)-0.5),0:(origsze(2)-0.5)); % Creates original meshgrid so that the interpolation function knows where to start interpolating in space. 
    [x2,y2] = ndgrid(0.5:2:(origsze(1)-1.5),0:2:(origsze(2)-1.5)); % Creates the downsampled grid.
    scimatout = interpn(x1,y1,scimat.data,x2,y2);
    
    % Update scimat 
    scimat.data = scimatout;
    

    % Need to change the coordinates of first voxel
    scimat.axis(1).min  = coords(1,1,2) - ([scimat.axis(2).spacing]/2);
    scimat.axis(2).min  = coords(1,1,1) - ([scimat.axis(1).spacing]/2);
    scimat.axis(3).min  = coords(1,1,3) - ([scimat.axis(3).spacing]/2);
    
end
end
