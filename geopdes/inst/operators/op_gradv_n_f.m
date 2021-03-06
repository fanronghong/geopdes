% OP_GRADV_N_F: assemble the right hand-side vector r = [r(i)], r(i) = (epsilon (grad v n)_i, f).
%
%   rhs = op_gradv_n_f (spv, msh, coeff);
%
% INPUT:
%
%   spv:   structure representing the space of test functions (see sp_scalar/sp_evaluate_col)
%   msh:   structure containing the domain partition and the quadrature rule for the boundary, 
%           since it must contain the normal vector (see msh_cartesian/msh_eval_boundary_side)
%   coeff: vector-valued function f, evaluated at the quadrature points
%
% OUTPUT:
%
%   rhs: assembled right-hand side
% 
% Copyright (C) 2014 Adriano Cortes
% Copyright (C) 2014, 2017 Rafael Vazquez
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

function rhs = op_gradv_n_f (spv, msh, coeff)

  rhs = zeros(spv.ndof,1);  

  gradv = reshape (spv.shape_function_gradients, spv.ncomp, [], ...
		   msh.nqn, spv.nsh_max, msh.nel);

  coeff = reshape (coeff, spv.ncomp, msh.nqn, msh.nel);

  ndim = size (gradv, 2);

  jacdet_weights = reshape (msh.jacdet .* msh.quad_weights, [1, msh.nqn, msh.nel]);
  coeff_times_jw = bsxfun (@times, jacdet_weights, coeff);
  
  for iel = 1:msh.nel
    if (all (msh.jacdet(:,iel)))
      gradv_iel = gradv(:,:,:,:,iel);
      normal_iel = reshape (msh.normal(:,:,iel), [1, ndim, msh.nqn]);

      gradv_n = reshape (sum (bsxfun (@times, gradv_iel, normal_iel), 2), spv.ncomp, msh.nqn, spv.nsh_max);

      aux_val = bsxfun (@times, coeff_times_jw(:,:,iel), gradv_n);
      rhs_loc = sum (sum (aux_val, 1), 2);

      indices = find (spv.connectivity(:,iel));
      rhs_loc = rhs_loc(indices); conn_iel = spv.connectivity(indices,iel);
      rhs(conn_iel) = rhs(conn_iel) + rhs_loc(:);
    else
      warning ('geopdes:jacdet_zero_at_quad_node', 'op_gradv_n_f: singular map in element number %d', iel)
    end
  end
  
end
