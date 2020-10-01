
%-----------------------------------------------------------
% System Parameters
%-----------------------------------------------------------
% Parameters
Tsymb = 1e-3; % Symbol Period
Ts    = Tsymb/16; % Sampling Period
% Pulse
E_pulse = 1e-6;
%-----------------------------------------------------------


[pulse n_fir] = pulse(Ts,Tsymb,'rrc');


spar.Tsymb   = Tsymb;
spar.Ts      = Ts;

spar.n_bytes = 4;  % Number of bytes transmitted per transmission
spar.n_pre   = 16; % Length of preamble symbols
spar.n_sfd   = 2;  % Length of sfd

spar.pulse   = pulse;
spar.n_pulse = Tsymb/Ts;
spar.E_pulse = E_pulse;
spar.n_fir   = n_fir;

spar.det_th  = 0.25;

spar.pll.kp    = 0.7;
spar.pll.ki    = 0.01;
spar.pll.delay = 0;



