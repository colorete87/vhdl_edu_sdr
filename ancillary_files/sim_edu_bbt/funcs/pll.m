%-----------------------------------------------------------
% PLL implementation
%
% Description:
%   f0: VCO center frequency
%   fs: Sampling frequency
%   kp: Proportional constant
%   ki: Integrator constant
%
%   TODO
%
%-----------------------------------------------------------
function [vco pllis] =  pll(input, f0, fs, kp, ki, delay);
%-----------------------------------------------------------

  %---------------------------------------
  % Initialize signals
  %---------------------------------------
  if not(exist('delay', 'var'))
    delay = 0;
  end
  phi_hat = zeros(1,1+delay);
  err     = zeros(1,1+delay);
  phd     = zeros(1,1+delay);
  vco     = zeros(1,1+delay);
  int_err = zeros(1,1+delay);
  %---------------------------------------

  %---------------------------------------
  % PLL loop: input by input
  % for it = 2:length(input)
  for it = 2+delay:length(input)

    % Compute VCO
    % The input for the VCO is the phase (phi_hat)
    vco(it)     = conj(exp(j*(2*pi*it*f0/fs+phi_hat(it-1-delay))));

    % Complex multiply VCO x Input
    % Phase estimation
    phd(it)     = imag(input(it)*vco(it));

    % Filter integrator
    % Phase estimation integration
    % err(it)     = err(it-1)+(kp+ki)*phd(it)-ki*phd(it-1);
    % err(it)     = (kp+ki)*phd(it)+ki*phd(it-1);
    int_err(it) = ki*phd(it)+int_err(it-1);
    err(it)     = kp*phd(it)+int_err(it);

    % Updata VCO
    phi_hat(it) = phi_hat(it-1)+err(it);
    % phi_hat(it) = 0; % TODO: Uncomment to open loop

  end
  %---------------------------------------

  %---------------------------------------
  % Output the PLL Internal Signals
  pllis.phd     = phd;
  pllis.err     = err;
  pllis.phi_hat = phi_hat;
  %---------------------------------------

end
%-----------------------------------------------------------

