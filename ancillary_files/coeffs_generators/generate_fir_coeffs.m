close all;
clear all;
clc;

format('compact');
graphics_toolkit gnuplot;
addpath('./funcs/');


% Root-raised cosine parameters
Ts = 1e-3;
Beta = 0.5;

% FIR parameters
max_t = 3*Ts;
d_t = 1e-4;
n_bits_coef = 8;


t = d_t:d_t:max_t;
t = [-flip(t), 0, t];

% Raised Cosine
% g1 = 1/Ts*sinc(t/Ts).*cos(pi*Beta*t/Ts)./(1-(2*Beta*t/Ts).^2);
% g1(t==Ts/2/Beta) = pi/4/Ts*sinc(1/2/Beta);
% g1(t==-Ts/2/Beta) = pi/4/Ts*sinc(1/2/Beta);
g1 = raised_cosine(t, Ts, Beta);
g1 = g1./max(g1);

gg1 = g1*(2^(n_bits_coef-1)-1);

file_name = sprintf('../../rtl/fir_coeffs/rc_coeffs.v');
of = fopen(file_name, 'w');
for i = 1:length(t)
  if (round(gg1(i))>=0)
    str = sprintf('assign coeffs[%d] = %d''d%d;\n', i-1, n_bits_coef, round(gg1(i)));
  else
    str = sprintf('assign coeffs[%d] = %d''d%d;\n', i-1, n_bits_coef, round((2^n_bits_coef)+gg1(i)));
  end
  % disp(str);
  fprintf(of, str);
end
fclose(of);

figure(1); hold on;
stem(t,g1);
print('./data/g_vs_t.png', '-dpng');

figure(2); hold on;
stem(t,gg1,'bo');
stem(t,round(gg1),'rx');
print('./data/round_g_vs_t.png', '-dpng');




% Root-Raised Cosine
% a = sin(pi*t/Ts*(1-Beta)) + 4*Beta*t/Ts.*cos(pi*t/Ts*(1+Beta));
% b = pi*t/Ts.*(1-(4*Beta*t/Ts).^2);
% g2 = 1/Ts*a./b;
% g2(t==0) = 1/Ts*(1+Beta*(4/pi-1));
% g2(t==Ts/4/Beta) = Beta/Ts/sqrt(2)*((1+2/pi)*sin(pi/4/Beta)+(1-2/pi)*cos(pi/4/Beta));
% g2(t==-Ts/4/Beta) = Beta/Ts/sqrt(2)*((1+2/pi)*sin(pi/4/Beta)+(1-2/pi)*cos(pi/4/Beta));
g2 = root_raised_cosine(t, Ts, Beta);
g2 = g2./max(g2);

gg2 = g2*(2^(n_bits_coef-1)-1);

file_name = sprintf('../../rtl/fir_coeffs/rrc_coeffs.v');
of = fopen(file_name, 'w');
for i = 1:length(t)
  if (round(gg2(i))>=0)
    str = sprintf('assign coeffs[%d] = %d''d%d;\n', i-1, n_bits_coef, round(gg2(i)));
  else
    str = sprintf('assign coeffs[%d] = %d''d%d;\n', i-1, n_bits_coef, round((2^n_bits_coef)+gg2(i)));
  end
  % disp(str);
  fprintf(of, str);
end
fclose(of);

figure(3); hold on;
stem(t,g2);
print('g_vs_t.png', '-dpng');

figure(4); hold on;
stem(t,gg2,'bo');
stem(t,round(gg2),'rx');
print('round_g_vs_t.png', '-dpng');




