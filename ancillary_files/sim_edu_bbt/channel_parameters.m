

Pn = 0.1;
Pn = 0.01;
Pn = 0.001;
Pn = 0.0001;
Pn = 1e-6;

h(1)  = 1/2;
% h(4)  = 0.5;
% h(16) = 0.5;
% h(31) = 0.3;
% h(58) = 0.5;

if length(h) == 1
  h(2) = 0;
end

cpar.Pn = Pn;
cpar.h  = h;
