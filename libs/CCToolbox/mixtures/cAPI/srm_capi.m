function M = srm_capi(trajs,K,Ops)
%SRM_CAPI  Curve API for SRM model.
%
%   Model = SRM_CAPI(Trajs,K,Options)
%    - Trajs : 'Trajs' structure (see HELP CCToolbox)
%    - K     : number of clusters to find

% Scott Gaffney   9 October 2003
% Department of Information and Computer Science
% University of California, Irvine

PROGNAME = 'srm_capi';
METHOD = PROGNAME;
if (~nargin)
  try; help(PROGNAME); catch; end
  return;
end

%%% Handle Argument Processing
%%%
n = nargin;
if (n<3)
  error([PROGNAME, ': incorrect number of parameters provided.']);
end
%%
%%% End Argument Processing


% Ops Handling
Ops = SetFieldDef(Ops,'order','4');
Ops = SetFieldDef(Ops,'knots',[]);

M = srm(trajs,K,Ops.knots,Ops.order,Ops);

