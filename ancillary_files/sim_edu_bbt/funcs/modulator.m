

function [x_n mis] = modulator(byte_seq, spar)% n_pre, pulse, n_pulse)

  assert(all(byte_seq<=255));

  n_bytes = length(byte_seq);

  pre          = zeros(1,spar.n_pre);
  pre(2:2:end) = 1;
  sfd          = zeros(1,spar.n_sfd);
  if mod(spar.n_pre,2)==0
    sfd(1:2:end) = 1;
  else
    sfd(2:2:end) = 1;
  end
  data = [];
  for i = 1:n_bytes
    bin_str = dec2bin(byte_seq(i),8);
    bin = [];
    for j = 1:8
      bin = [bin str2num(bin_str(j))];
    end
    data = [data bin];
  end
  packet = [pre sfd data];
  % length(pre)
  % length(sfd)
  % length(data)
  n_packet = length(packet);

  % Mapper
  x     = 2*packet-1;

  % Pulse shaping
  xx    = upsample(x,spar.n_pulse);
  xxx   = conv(xx,spar.pulse);
  % n_xxx = length(xxx);

  x_n = xxx;
  d   = packet;

  % Modulator Internal Signals (MIS)
  mis.d = d;

end
