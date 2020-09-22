%function [b,a]= bp_synth(N,fcenter,bw,fs)      12/29/17 neil robertson
% Synthesize IIR Butterworth Bandpass Filters
%
% N= order of prototype LPF
% fcenter= center frequency, Hz
% bw= -3 dB bandwidth, Hz
% fs= sample frequency, Hz
% [b,a]= vector of filter coefficients
%
function [b,a]= bp_synth(N,fcenter,bw,fs)
f1= fcenter- bw/2;            % Hz lower -3 dB frequency
f2= fcenter+ bw/2;            % Hz upper -3 dB frequency
if f2>=fs/2;
   error('fcenter+ bw/2 must be less than fs/2')
end
if f1<=0
   error('fcenter- bw/2 must be greater than 0')
end
% find poles of butterworth lpf with Wc = 1 rad/s
k= 1:N;
theta= (2*k -1)*pi/(2*N);
p_lp= -sin(theta) + j*cos(theta);    
% pre-warp f0, f1, and f2
F1= fs/pi * tan(pi*f1/fs);
F2= fs/pi * tan(pi*f2/fs);
BW_hz= F2-F1;              % Hz prewarped -3 dB bandwidth
F0= sqrt(F1*F2);           % Hz geometric mean frequency
% transform poles for bpf centered at W0
% note:  alpha and beta are vectors of length N; pa is a vector of length 2N
alpha= BW_hz/F0 * 1/2*p_lp;
beta= sqrt(1- (BW_hz/F0*p_lp/2).^2);
pa= 2*pi*F0*[alpha+j*beta  alpha-j*beta];
% find poles and zeros of digital filter
p= (1 + pa/(2*fs))./(1 - pa/(2*fs));      % bilinear transform
q= [-ones(1,N) ones(1,N)];                % N zeros at z= -1 (f= fs/2) and z= 1 (f = 0)
% convert poles and zeros to numerator and denominator polynomials
a= poly(p);
a= real(a);
b= poly(q);
% scale coeffs so that amplitude is 1.0 at f0
f0= sqrt(f1*f2);
h= freqz(b,a,[f0 f0],fs);
K= 1/abs(h(1));
b= K*b;
