
function [p n_fir] = pulse(Ts,Tsymb,type)

  n_pulse = Tsymb/Ts;
  assert(floor(n_pulse)==n_pulse);

  %-----------------------------------------------------------
  % Pulse: Square
  % ----------------
  n_fir1 = n_pulse;
  pulse1 = ones(1,n_pulse);
  aux_E1 = Tsymb*1;
  %-----------------------------------------------------------


  %-----------------------------------------------------------
  % Pulse: Sin
  % ----------------
  n_fir2 = n_pulse;
  if mod(n_pulse,2) == 0
    aux_t  = 0:Ts:Tsymb-Ts;
  else
    aux_t  = Ts/2:Ts:Tsymb-Ts/2;
  end
  pulse2 = sin(pi/Tsymb*aux_t);
  aux_E2 = Tsymb/2;
  %-----------------------------------------------------------

  %-----------------------------------------------------------
  % Pulse: (Root)-Raised Cosine params
  % ----------------
  Beta   = 0.5;
  n_fir3 = n_pulse*5-1;
  n_fir4 = n_pulse*5-1;
  assert(mod(n_fir3,2)==1 && n_fir3>=n_pulse);
  %
  aux_t = Ts:Ts:(Ts*(n_fir3-1)/2);
  aux_t = [-fliplr(aux_t), 0, aux_t];
  % Raised Cosine
  pulse3 = raised_cosine(aux_t,Tsymb,Beta);
  pulse3 = pulse3./max(pulse3);
  aux_E  = Tsymb;
  % Root-Raised Cosine
  pulse4 = root_raised_cosine(aux_t,Tsymb,Beta);
  pulse4 = pulse4./max(pulse4);
  aux_E  = Tsymb;
  %-----------------------------------------------------------


  %-----------------------------------------------------------
  % Elijo el pulso
  switch(type)
    case 'square'
      n_fir = n_fir1;
      p     = pulse1;
    case 'sin'
      n_fir = n_fir2;
      p     = pulse2;
    case 'rc'
      n_fir = n_fir3;
      p     = pulse3;
    case 'rrc'
      n_fir = n_fir4;
      p     = pulse4;
  end
  % ----------------
  % Normalizao la energía del pulso
  % pulse = pulse./sqrt(aux_E)*sqrt(E_pulse);
  %-----------------------------------------------------------

end
