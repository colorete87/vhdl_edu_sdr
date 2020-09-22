function y = channel(x,cpar)

  sigma = sqrt(cpar.Pn);

  y = filter(cpar.h,[1],x);

  y = y+sigma*randn(size(x));

end
