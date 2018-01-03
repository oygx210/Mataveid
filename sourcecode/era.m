% Eigensystem Realization Algorithm 
% Input: g, h, nu, delay(optional)
% Example [sysd] = era(g, h, nu, delay);
% Author: Daniel Mårtensson, November 2017

function [sysd] = era(varargin)
  % Check if there is any input
  if(isempty(varargin))
    error('Missing imputs')
  end
  
  % Get impulse response
  if(length(varargin) >= 1)
    g = varargin{1};
  else
    error('Missing impulse response')
  end
  
  % Get the sample time
  if(length(varargin) >= 2)
    sampleTime = varargin{2};
  else
    error('Missing sample time');
  end
  
  % Get the number of input
  if(length(varargin) >= 3)
    nu = varargin{3};
  else
    error('Missing number of input');
  end
  
  % Get the delay
  if(length(varargin) >= 4)
    delay = varargin{4};
  else
    delay = 0; % If no delay was given
  end
  
  % Check if g can be diveded with 2
  if mod(length(g), 2) > 0
    error('The output cannot be divided with 2')
  end

  % Create hankel matrecies
  H0 = hank(g, 1);
  H1 = hank(g, 2);
  
  % Do SVD on H0
  [U,S,V] = svd(H0, 'econ');
  
  % Do model reduction
  [Un, En, Vn, nx] = modelReduction(U, S, V);
  
  % Create scalar for Bb, Cd
  ny = size(g, 1); % Number of outputs, we already know the number of inputs
  Ey = [eye(ny) zeros(ny,size(Un*En^(1/2),1) - size(eye(ny),1))]';
  Eu = [eye(nu) zeros(nu,size(En^(1/2)*Vn',2) - size(eye(nu),2))]';
  
  % Create matrix
  Ad = En^(-1/2)*Un'*H1*Vn*En^(-1/2);
  Bd = En^(1/2)*Vn'*Eu;
  Cd = Ey'*Un*En^(1/2);
  Dd = zeros(ny, nu);
  
  % Create state space model now
  sysd = ss(delay, Ad, Bd, Cd, Dd);
  sysd.sampleTime = sampleTime;
end

function [H] = hank(g, k)
  % Create hankel matrix
  H = cell(length(g)/2,length(g)/2); 
  
  for i = 1:length(g)/2
    for j = 1:length(g)/2
      H{i,j} = g(:,k+i+j-2);
    end
  end
  
  % Cell to matrix
  H = cell2mat(H);
end

function [U1, S1, V1, nx] = modelReduction(U, S, V)
  % Plot singular values 
  stem(1:length(S), diag(S));
  title('Hankel Singular values');
  xlabel('Amount of singular values');
  ylabel('Value');
  
  % Choose system dimension n - Remember that you can use modred.m to reduce some states too!
  nx = inputdlg('Choose the state dimension by looking at hankel singular values: ');
  nx = str2num(cell2mat(nx));
  
  % Choose the dimension nx
  U1 = U(:, 1:nx);
  S1 = S(1:nx, 1:nx);
  V1 = V(:, 1:nx);
end