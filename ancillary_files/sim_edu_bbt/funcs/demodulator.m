
function [hat_bytes dis] = demodulator(y,spar) % n_bytes,pulse,n_pulse)

  n_pulse = spar.Tsymb/spar.Ts;
  n_bytes = spar.n_bytes;

  % Matched filter
  y_mf = filter(spar.pulse,[1],y);
  y_mf = y_mf./sum(spar.pulse.^2);

  % Squared input and filtered with moving average
  y_mf_sq    = y_mf.^2;
  n_ma       = spar.n_pulse;
  % n_ma       = ceil(spar.n_pulse/2);
  % n_ma       = 32;
  y_mf_sq_ma = filter(ones(1,n_ma)./n_ma,[1],y_mf_sq);

  % PreFilter, SQuare, BandPassFilter
  prefilter_data     = dlmread('../coeffs_generators/data/symb_sync_pre_filter.dat');
  prefilter_b        = prefilter_data(1,:);
  prefilter_a        = prefilter_data(2,:);
  filter_data        = dlmread('../coeffs_generators/data/symb_sync_bp_filter.dat');
  filter_b           = filter_data(1,:);
  filter_a           = filter_data(2,:);
  y_mf_pf            = filter(prefilter_b,prefilter_a,y_mf);
  % y_mf_pf            = y_mf; % NOTE: descomentar para eliminar el pre-filter
  y_mf_pf_sq         = y_mf_pf.^2;
  y_mf_pf_sq_bpf     = filter(filter_b,filter_a,y_mf_pf_sq);
  % y_mf_pf_sq_bpf     = y_mf_pf_sq; % NOTE: descomentar para eliminar el bp-filter

  % pll
  f0    = 1./spar.Tsymb;
  fs    = 1./spar.Ts;
  kp    = spar.pll.kp;
  ki    = spar.pll.ki;
  delay = spar.pll.delay;
  [vco pllis] = pll(y_mf_pf_sq_bpf,f0,fs,kp,ki,delay);

  % pll clk signals
  pll_cos        = real(vco);
  pll_sin        = imag(vco);
  pll_clk_i      = pll_cos>=0;
  pll_clk_q      = pll_sin>=0;

  % Simbol detection
  detection  = y_mf_sq_ma>=spar.det_th;
  det_start  = ~detection & [0  detection(1:end-1)];
  det_stop   =  detection & [0 ~detection(1:end-1)];
  flank_qp   = ~pll_clk_q & [0  pll_clk_q(1:end-1)];
  flank_qn   =  pll_clk_q & [0 ~pll_clk_q(1:end-1)];
  flank_ip   = ~pll_clk_i & [0  pll_clk_i(1:end-1)];
  flank_in   =  pll_clk_i & [0 ~pll_clk_i(1:end-1)];
  flank      = flank_in;
  en_sample  = flank & detection;
  hat_xn     = y_mf(en_sample==1);
  hat_packet = hat_xn>0;
  sfd        = zeros(1,spar.n_sfd);
  if mod(spar.n_pre,2)==0
    sfd(1:2:end) = 1;
  else
    sfd(2:2:end) = 1;
  end
  det_count = zeros(size(detection));
  idx       = find(det_start==1);
  idx       = find(det_stop==1);
  for i = 1:length(idx)
    det_count(idx(i):end) = det_count(idx(i):end)+1;
  end
  det_count = det_count(en_sample==1);
  hat_data  = [];
  hat_bytes = [];
  n_det     = max(det_count);
  for i = 1:n_det
    aux_pos   = det_count==i;
    aux_packet = zeros(size(hat_packet));
    aux_packet(aux_pos) = hat_packet(aux_pos);
    pattern   = flip([~sfd sfd]*2-1);
    n_pat     = length(pattern);
    idx_start = min(find(conv(aux_packet*2-1,pattern,'valid')==n_pat))+n_pat;
    idx_stop  = max(find(aux_pos));
    % [idx_start idx_stop idx_stop-idx_start]
    if idx_stop<=idx_start
      continue;
    end
    hat_d_aux = hat_packet(idx_start:idx_stop-1);
    hat_data = [hat_data hat_d_aux];
    if mod(length(hat_d_aux),8)==0
      for j = 1:length(hat_d_aux)/8
        aux = flip(2.^(0:7));
        % [j j*8 length(hat_d_aux)]
        aux = aux.*hat_d_aux((j-1)*8+1:j*8);
        byte = sum(aux);
        hat_bytes = [hat_bytes byte];
      end
    else
      continue;
    end
  end

  % Detector
  hat_dn = hat_data;
  % bytes  = hat_dn>0;

  % Demodulator Internal Signals (DIS)
  dis.y_mf           = y_mf;
  dis.y_mf_sq        = y_mf_sq;
  dis.y_mf_sq_ma     = y_mf_sq_ma;
  dis.y_mf_pf        = y_mf_pf;
  dis.y_mf_pf_sq     = y_mf_pf_sq;
  dis.y_mf_pf_sq_bpf = y_mf_pf_sq_bpf;
  dis.detection      = detection;
  dis.sfd            = sfd;
  dis.flank_qp       = flank_qp;
  dis.flank_qn       = flank_qn;
  dis.flank_ip       = flank_ip;
  dis.flank_in       = flank_in;
  dis.en_sample      = en_sample;
  dis.hat_xn         = hat_xn;
  dis.hat_packet     = hat_packet;
  dis.vco            = vco;
  dis.pllis          = pllis;
  dis.pll_cos        = real(vco);
  dis.pll_sin        = imag(vco);
  dis.pll_clk_i      = pll_cos>=0;
  dis.pll_clk_q      = pll_sin>=0;
  dis.hat_dn         = hat_dn;

end
