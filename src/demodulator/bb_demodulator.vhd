-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity
entity bb_demodulator is
  port
  (
    -- clk, en, rst
    clk_i         : in  std_logic;
    en_i          : in  std_logic;
    srst_i        : in  std_logic;
    -- Input Stream
    is_data_i     : in  std_logic_vector( 9 downto 0);
    is_dv_i       : in  std_logic;
    is_rfd_o      : out std_logic;
    -- Output Stream
    os_data_o     : out std_logic_vector( 7 downto 0);
    os_dv_o       : out std_logic;
    os_rfd_i      : in  std_logic;
    -- Config
    nm1_bytes_i   : in  std_logic_vector( 7 downto 0);
    nm1_pre_i     : in  std_logic_vector( 7 downto 0);
    nm1_sfd_i     : in  std_logic_vector( 7 downto 0);
    det_th_i      : in  std_logic_vector(15 downto 0);
    pll_kp_i      : in  std_logic_vector(15 downto 0);
    pll_ki_i      : in  std_logic_vector(15 downto 0);
    -- State
    rx_ovf_o      : out std_logic
  );
end entity bb_demodulator;

-- architecture
architecture rtl of bb_demodulator is

  component matched_filter_fir is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(9 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component matched_filter_fir;

  component shift_reg is
    generic (
      sr_depth : integer;
      sr_width : integer
    );
    port (
      clk    : in  std_logic;
      rst    : in  std_logic; -- Optional
      en     : in std_logic;
      sr_in  : in  std_logic_vector(sr_width - 1 downto 0);
      sr_out : out std_logic_vector(sr_width - 1 downto 0)
    );
  end component;

  component symb_sync is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector( 9 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Config
      pll_kp_i      : in  std_logic_vector(15 downto 0);
      pll_ki_i      : in  std_logic_vector(15 downto 0);
      -- Output
      en_sample_o   : out std_logic;
      -- State
      locked_o      : out std_logic
    );
  end component symb_sync;

  component dem_control_unit is
    port(
      -- clk, en, rst
      clk_i           : in  std_logic;
      en_i            : in  std_logic;
      srst_i          : in  std_logic;
      -- Config
      nm1_bytes_i     : in  std_logic_vector(7 downto 0);
      nm1_pre_i       : in  std_logic_vector(7 downto 0);
      nm1_sfd_i       : in  std_logic_vector(7 downto 0);
      -- Input
      bit_i           : in  std_logic;
      new_bit_i       : in  std_logic;
      signal_det_i    : in  std_logic;
      -- Output
      bit_counter_o   : out std_logic_vector(10 downto 0);
      data_det_o      : out std_logic
    );
  end component;

  component moving_average is
    generic (
      NBIT         : integer := 8;
      DEPTH        : integer := 16
    );
    port (
      clk_i        : in  std_logic;
      srst_i       : in  std_logic;
      en_i         : in  std_logic;
      -- input
      data_i       : in  std_logic_vector(NBIT-1 downto 0);
      -- output
      data_o       : out std_logic_vector(NBIT-1 downto 0);
      data_valid_o : out std_logic
    );
  end component;

  -- constants
  constant N_PULSE   : integer := 16;

  -- signals
  -- Modulator output
  signal mf_data_s        : std_logic_vector(9 downto 0);
  signal mf_dv_s          : std_logic;
  signal mf_rfd_s         : std_logic;
  signal mf_data_d_s      : std_logic_vector(9 downto 0);
  signal mf_sq_s          : std_logic_vector(9 downto 0);
  signal mf_sq_ma_s       : std_logic_vector(9 downto 0);

  -- Shift register
  signal sr_en_s          : std_logic;

  -- Signal detection
  signal signal_det_aux_s : std_logic;
  signal signal_det_s     : std_logic;

  -- Sampler
  signal en_sample0_s     : std_logic;
  signal sample0_s        : std_logic_vector(9 downto 0);
  signal bit0_s           : std_logic;
  signal new_bit0_s       : std_logic;

  -- Synchronized bit, sample, counter and data_detection
  signal sample_s         : std_logic_vector(9 downto 0);
  signal bit_s            : std_logic;
  signal new_bit_s        : std_logic;
  signal bit_counter_s    : std_logic_vector(10 downto 0);
  signal data_det_s       : std_logic;

  -- Byte signals
  signal byte_s           : std_logic_vector(7 downto 0);
  signal new_byte_s       : std_logic;

  -- Output signals
  signal os_dv_s          : std_logic;
                          
begin


  u_matched_filter : matched_filter_fir
  port map(
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => is_data_i,
    is_dv_i       => is_dv_i,
    is_rfd_o      => is_rfd_o,
    -- Output Stream
    os_data_o     => mf_data_s,
    os_dv_o       => mf_dv_s,
    os_rfd_i      => mf_rfd_s
  );

  -- Shift Register
  sr_en_s <= en_i and mf_dv_s and mf_rfd_s;
  u_shift_reg : shift_reg
  generic map (
    sr_depth => 5,
    sr_width => 10
  )
  port map (
    clk    => clk_i,
    rst    => srst_i,
    en     => sr_en_s,
    sr_in  => mf_data_s,
    sr_out => mf_data_d_s
  );

  u_symb_sync : symb_sync
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => mf_data_s,        
    is_dv_i       => mf_dv_s,         
    is_rfd_o      => mf_rfd_s,       
    -- Config
    pll_kp_i      => pll_kp_i,
    pll_ki_i      => pll_ki_i,
    -- Output
    en_sample_o   => en_sample0_s,
    -- State
    locked_o      => open
  );

  -- Sampler
  u_sampler : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        sample0_s      <= (others => '0');
        bit0_s         <= '0';
        new_bit0_s     <= '0';
        signal_det_s   <= '0';
      else
        if en_sample0_s = '1' then
          sample0_s    <= mf_data_d_s;
          bit0_s       <= not(mf_data_d_s(9));
          signal_det_s <= signal_det_aux_s;
        end if;
        new_bit0_s <= en_sample0_s;
      end if;
    end if;
  end process;

  -- Square law and register
  u_sq : process(clk_i)
    variable aux_v : unsigned(19 downto 0);
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        mf_sq_s <= (others => '0');
      else
        if en_i = '1' then
          aux_v := unsigned(signed(mf_data_s) * signed(mf_data_s));
          mf_sq_s <= std_logic_vector(aux_v(15 downto 6)); -- TODO a ojo
        end if;
      end if;
    end if;
  end process;
  -- Moving Average
  u_moving_average : moving_average
  generic map (
    NBIT   => 10,
    DEPTH  => 16
  )
  port map (
    clk_i        => clk_i,
    srst_i       => srst_i,
    en_i         => sr_en_s,
    data_i       => mf_sq_s,
    data_o       => mf_sq_ma_s,
    data_valid_o => open
  );
  -- Comparator
  signal_det_aux_s <='1' when unsigned(mf_sq_ma_s) > unsigned(det_th_i) else '0';

  --signal_det_aux_s <='1' when unsigned(mf_sq_s) > unsigned(det_th_i) else '0';
  ---- Persistent signal detection
  --u_sq_persistent : process (clk_i)
  --  variable counter_v   : integer;
  --  constant PERSISTENCE : integer := N_PULSE/2;
  --begin
  --  if (rising_edge(clk_i)) then
  --    if srst_i = '1' then
  --      signal_det_s <= '0';
  --      counter_v := 0;
  --    else
  --      if en_i = '1' then
  --        if signal_det_aux_s = '1' then
  --          signal_det_s <= '1';
  --          counter_v := PERSISTENCE;
  --        else
  --          counter_v := counter_v - 1;
  --          if counter_v = 0 then
  --            signal_det_s <= '0';
  --          end if;
  --        end if;
  --      end if;
  --    end if;
  --  end if;
  --end process;

  -- Control Unit and synchornized bit, sample, counter and data_detection
  u_bit_sample_reg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        bit_s     <= '0';
        new_bit_s <= '0';
        sample_s  <= (others => '0');
      else
        if en_i = '1' then
          bit_s     <= bit0_s;
          new_bit_s <= new_bit0_s;
          sample_s  <= sample0_s;
        end if;
      end if;
    end if;
  end process;
  u_dem_cu : dem_control_unit 
  port map
  (
    -- clk, en, rst
    clk_i           => clk_i,
    en_i            => en_i,
    srst_i          => srst_i,
    -- Config
    nm1_bytes_i     => nm1_bytes_i,
    nm1_pre_i       => nm1_pre_i,
    nm1_sfd_i       => nm1_sfd_i,
    -- Input
    bit_i           => bit0_s,
    new_bit_i       => new_bit0_s,
    signal_det_i    => signal_det_s,
    -- Output
    bit_counter_o   => bit_counter_s,
    data_det_o      => data_det_s
  );

  -- Byte
  u_s2p : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        byte_s     <= (others => '0');
        new_byte_s <= '0';
      else
        if en_i = '1' then
          byte_s(to_integer(unsigned(bit_counter_s(2 downto 0)))) <= bit_s;
          if bit_counter_s(2 downto 0) = "111" and data_det_s = '1' then
            new_byte_s    <= new_bit_s;
          else
            new_byte_s <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Output Stream data valid
  u_os_if : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        os_data_o  <= (others => '0');
        os_dv_s    <= '0';
        rx_ovf_o   <= '0';
      else
        if en_i = '1' then
          if new_byte_s = '1' then
            os_data_o  <= byte_s;
            os_dv_s    <= '1';
          end if;
          if os_rfd_i = '1' and os_dv_s = '1' then
            os_dv_s    <= '0';
          end if;
          if os_rfd_i = '0' and os_dv_s = '1' and new_byte_s = '1' then
            rx_ovf_o <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  os_dv_o <= os_dv_s;


end architecture rtl;

