function [trajs,M] = rm_ab_sim(M,NumSamps,len,ops)
%RM_AB_SIM  Simulate from a *RM_AB model.
%   [TRAJS,M] = RM_AB_SIM(M,NUM_SAMPS,[LEN],[Ops])

% Scott J Gaffney   4 October 2001
% Department of Information and Computer Science
% University of California, Irvine.

PROGNAME = 'rm_ab_sim';
if (~nargin)
  try; help(PROGNAME); catch; end
  return;
end

len = cexist('len',[]);
ops = cexist('ops',[]);
ops = SetFieldDef(ops,'SampleAt',[]);
ops = SetFieldDef(ops,'SampMinLen',1);
ops = SetFieldDef(ops,'SampMaxLen',10);
ops = SetFieldDef(ops,'DoPerturb',0);
ops = SetFieldDef(ops,'Perturb_Std',.1);


% Handle specified sampling vector
if (~isempty(ops.SampleAt))
  lensamp = length(ops.SampleAt);
  ops.SampMaxLen = lensamp;
end

% Handle length specifier
if (isempty(len))
  len = floor(rand(NumSamps,1)*(ops.SampMaxLen+1-ops.SampMinLen)) ...
    + ops.SampMinLen;
elseif (length(len)==1)
  len = len(ones(NumSamps,1));
end

% Stratify the sample according to the priors
C = pmfrnd(M.Alpha, NumSamps);
C = sort(C);   C=C(:);  % sort them just because

% Set the sample range
if (isempty(ops.SampleAt))
  samp = (0:max(len)-1)'; 
else
  if (any(len>lensamp))
    fprintf('RM_AB_SIM: WARNING; invalid lengths, reducing max.\n');
    len(find(len>lensamp)) = lensamp;
  end
  samp = ops.SampleAt(:);
end

% messy way to select the method
DoSRM = 0;
if (isfield(M,'method'))
  if (M.method(1)=='s')
    DoSRM = 1;
  end
elseif (isfield(M,'knots'))
  DoSRM = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform the sampling
[P,K,D] = size(M.Mu);
M.a = zeros(NumSamps,1);
M.b = zeros(NumSamps,1);
if (ops.DoPerturb | ~isempty(ops.SampleAt))
  xx = zeros(sum(len),1);
  start=1;
end

for i=1:NumSamps
  ni = len(i);
  x = samp(1:ni);
  
  % handle random perturbation of the sampling value
  if (ops.DoPerturb | ~isempty(ops.SampleAt))
    indx = start:start+ni-1;  start = start+ni;
    if (ops.DoUniformPerturb)
      x = rand(ni,1)*samp(ni);
    elseif (ops.DoPerturb)
      x = x + randn(ni,1)*ops.Perturb_Std;
    end
    x = sort(x);
    xx(indx) = x;
  end
  
  M.a(i,1) = randn(1).*sqrt(M.R(C(i))) + 1;  % a ~ N(1,r^2)
  M.b(i,1) = randn(1).*sqrt(M.S(C(i)));      % b ~ N(0,s^2)
  if (M.a(i)<0), M.a(i)=-M.a(i);  end
  for d=1:D
    Eps = randn(ni,1)*sqrt(M.Sigma(C(i),d));
    if (DoSRM)
      X = bsplinebasis(M.knots,M.order,M.a(i).*x-M.b(i));
    else
      X = regmat(M.a(i).*x-M.b(i),P-1);
    end
    trajs{i}(:,d) = X*M.Mu(:,C(i),d) + Eps;
  end
end
M.TrueC = C;
if (ops.DoPerturb | ~isempty(ops.SampleAt))
  M.x = xx;
end
