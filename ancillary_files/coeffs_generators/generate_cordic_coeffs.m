close all;
clear all;
clc;

format('compact');
graphics_toolkit gnuplot;

% CORDIC parameters
n_bits_coef = 16;

% Atan MatrixRaised Cosine
v = 0:n_bits_coef-1;
atan_f = atan(2.^-v);
atan_d = round(atan_f/atan_f(1)*2^(n_bits_coef-2));
data   = atan_d;


file_name = sprintf('../../rtl/cordic/coeffs/cordic_coeffs.v');
of = fopen(file_name, 'w');
for i = 1:length(v)
  if (round(data(i))>=0)
    str = sprintf('assign atan_matrix[%d] = %d''d%d;\n', i-1, n_bits_coef, round(data(i)));
  else
    str = sprintf('assign atan_matrix[%d] = %d''d%d;\n', i-1, n_bits_coef, round((2^n_bits_coef)+data(i)));
  end
  % disp(str);
  fprintf(of, str);
end
fclose(of);

