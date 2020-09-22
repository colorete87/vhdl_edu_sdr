%-----------------------------------------------------------
% Root-Raise Cosine function
%
% Description:
%   TODO
%
%-----------------------------------------------------------
function y = root_raised_cosine (t, Tsymb, Beta)
%-----------------------------------------------------------

  %---------------------------------------
  a = sin(pi*t/Tsymb*(1-Beta)) + 4*Beta*t/Tsymb.*cos(pi*t/Tsymb*(1+Beta));
  b = pi*t/Tsymb.*(1-(4*Beta*t/Tsymb).^2);
  y = 1/Tsymb*a./b;
  y(t==0) = 1/Tsymb*(1+Beta*(4/pi-1));
  y(t==Tsymb/4/Beta) = Beta/Tsymb/sqrt(2)*((1+2/pi)*sin(pi/4/Beta)+(1-2/pi)*cos(pi/4/Beta));
  y(t==-Tsymb/4/Beta) = Beta/Tsymb/sqrt(2)*((1+2/pi)*sin(pi/4/Beta)+(1-2/pi)*cos(pi/4/Beta));
  %---------------------------------------

end
%-----------------------------------------------------------
