close all;
clear all;
clc;

format('compact');
graphics_toolkit gnuplot;


n_bits = 8;

% PSK
for nn = [4 8 16 32 64 128 256];
  file_name = sprintf('../../rtl/mapper_constants/constants_%dpsk.v', nn);
  of = fopen(file_name, 'w');
  for i = 0:nn-1
    y(i+1) = sin(2*pi*i/nn) + j*cos(2*pi*i/nn);
  end
  figure(nn); axis('square');
  plot(y,'x');
  yy_i = real(y*(2^(n_bits-1)-1));
  yy_q = imag(y*(2^(n_bits-1)-1));
  % [max(yy_i) min(yy_i) max(yy_q) min(yy_i)]
  for i = 1:length(y)
    if (round(yy_i(i))>=0)
      str = sprintf('assign c_%dpsk_i[%d] = %d''d%d;\n', nn, i, n_bits, round(yy_i(i)));
    else
      str = sprintf('assign c_%dpsk_i[%d] = %d''d%d;\n', nn, i, n_bits, round((2^n_bits)+yy_i(i)));
    end
    fprintf(of, str);
  end
  for i = 1:length(y)
    if (round(yy_q(i))>=0)
      str = sprintf('assign c_%dpsk_q[%d] = %d''d%d;\n', nn, i, n_bits, round(yy_q(i)));
    else
      str = sprintf('assign c_%dpsk_q[%d] = %d''d%d;\n', nn, i, n_bits, round((2^n_bits)+yy_q(i)));
    end
    fprintf(of, str);
  end
  fclose(of);
end
return;


of = fopen('qam_constants.v', 'w');
% QAM
for nn = [4 16 64 256];
end

return;

ret
gg = g*(2^(n_bits-1)-1);
