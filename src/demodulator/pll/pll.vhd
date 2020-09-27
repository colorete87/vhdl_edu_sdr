-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity pll is
  generic
  (
    WORD_WIDTH        : integer := 16
    -- PHASE_DET_REG     : std_logic := '1';
    -- ERROR_REG         : std_logic := '1';
    -- VCO_PIPE_SCHEDULE : std_logic_vector := "0"&"0000"&"0000"&"0000"&"0000"
  );
  port
  (
    -- clk, en, rst
    clk_i           : in  std_logic;
    en_i            : in  std_logic;
    srst_i          : in  std_logic;
    -- Input Stream
    is_data_i       : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    -- is_dv_i         : in  std_logic;
    -- is_rfd_o        : out std_logic;
    -- Output Stream
    os_sin_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
    os_cos_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
    -- os_dv_o         : out std_logic;
    -- os_rfd_i        : in  std_logic;
    -- Config       
    freq_zqero_i    : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    pll_kp_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    pll_ki_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    -- State        
    phase_err_o     : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    phase_int_err_o : in  std_logic_vector(WORD_WIDTH-1 downto 0);
    phase_o         : in  std_logic_vector(WORD_WIDTH-1 downto 0)
  );
end entity pll;

-- architecture
architecture rtl of pll is

  component nco is
    generic (
      WW       : positive;       -- Width of parameters
      STAGES : positive; -- Number of CORDIC iterations
      FRAC_BITS  : positive;  -- Total fractional bits
      MAGNITUDE  : real := 1.0;
      RESET_ACTIVE_LEVEL : std_ulogic := '1'
    );
    port (
      Clock : in std_ulogic;
      Reset : in std_ulogic;
      Angle : in signed(WW-1 downto 0); -- Angle in brads (2**WW brads = 2*pi radians)
      Sin   : out signed(WW-1 downto 0);  -- Sine of Angle
      Cos   : out signed(WW-1 downto 0)   -- Cosine of Angle
    );
  end component;

  -- constants

  -- signals
  signal freq_zqero_s    : std_logic_vector(WORD_WIDTH-1 downto 0);
  signal pll_kp_s        : std_logic_vector(WORD_WIDTH-1 downto 0);
  signal pll_ki_s        : std_logic_vector(WORD_WIDTH-1 downto 0);
  --
  signal pll_cos_s       : signed(WORD_WIDTH-1 downto 0);
  signal pll_sin_s       : signed(WORD_WIDTH-1 downto 0);
  --
  signal phase_est_s     : std_logic_vector(2*WORD_WIDTH-1 downto 0);
  signal phase_err_s     : std_logic_vector(  WORD_WIDTH-1 downto 0);
  signal phase_s         : signed(2*WORD_WIDTH-1 downto 0);
  signal phase2_s        : signed(2*WORD_WIDTH-1 downto 0);
  signal angle_s         : signed(  WORD_WIDTH-1 downto 0);
  --
  signal prop_err_s      : std_logic_vector(2*WORD_WIDTH-1 downto 0);
  signal int_err_s       : std_logic_vector(2*WORD_WIDTH-1 downto 0);

begin

  -- Config Registers
  u_conf_reg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        freq_zqero_s <= (others => '0');
        pll_kp_s     <= (others => '0');
        pll_ki_s     <= (others => '0');
      else
        if en_i = '1' then
          freq_zqero_s <= freq_zqero_i;
          pll_kp_s     <= pll_kp_i;
          pll_ki_s     <= pll_ki_i;
        end if;
      end if;
    end if;
  end process;

  -- Phase Error estimation
  u_phase_err : process(clk_i)
    variable aux_v : signed (2*WORD_WIDTH-1 downto 0);
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        phase_est_s <= (others => '0');
      else
        if en_i = '1' then
          aux_v := pll_cos_s * signed(is_data_i);
          phase_est_s <= std_logic_vector(aux_v(2*WORD_WIDTH-1 downto 0));
          -- phase_est_s <= std_logic_vector(to_signed(12,2*WORD_WIDTH));
          -- phase_est_s <= std_logic_vector(to_signed(0,2*WORD_WIDTH));
        end if;
      end if;
    end if;
  end process;

  -- Proportional error
  u_prop_error : process(phase_est_s,pll_kp_s)
    -- variable aux_v : signed (3*WORD_WIDTH-1 downto 0);
  begin
    prop_err_s <= std_logic_vector(signed(phase_est_s(2*WORD_WIDTH-1 downto WORD_WIDTH)) * signed(pll_kp_s));
    -- aux_v := signed(phase_est_s) * signed(pll_kp_s);
    -- prop_err_s <= std_logic_vector(aux_v(2*WORD_WIDTH-1 downto 0));
  end process;

  -- Integral error
  u_integra_error : process(clk_i)
    -- variable aux_v : signed (3*WORD_WIDTH-1 downto 0);
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        int_err_s <= (others => '0');
        --aux_v := (others => '0');
      else
        if en_i = '1' then
          int_err_s <= std_logic_vector(signed(phase_est_s(2*WORD_WIDTH-1 downto WORD_WIDTH)) * signed(pll_ki_s));
          --aux_v := signed(phase_est_s(2*WORD_WIDTH-1 downto WORD_WIDTH) * signed(pll_ki_s);
          --int_err_s <= std_logic_vector(
          --               resize(signed(int_err_s), 2*WORD_WIDTH)
          --               +
          --               aux_v(2*WORD_WIDTH-1 downto 0)
          --             );
        end if;
      end if;
    end if;
  end process;

  -- Loop Filter
  u_loop_filter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        phase_err_s <= (others => '0');
      else
        if en_i = '1' then
          phase_err_s <= std_logic_vector(signed(prop_err_s(2*WORD_WIDTH-1 downto WORD_WIDTH)) +
                         signed(int_err_s(2*WORD_WIDTH-1 downto WORD_WIDTH)));
          -- phase_err_s <= std_logic_vector(to_signed(10,2*WORD_WIDTH));
        end if;
      end if;
    end if;
  end process;

  -- NCO Phase
  u_phase : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        phase_s <= (others => '0');
        phase2_s <= (others => '0');
      else
        if en_i = '1' then
          phase_s <= signed(phase_s) + signed(phase_err_s);
          phase2_s <= phase2_s + signed(freq_zqero_s);
        end if;
      end if;
    end if;
  end process;

  -- NCO
  angle_s <= phase2_s(WORD_WIDTH-1 downto 0) + phase_s(2*WORD_WIDTH-1 downto 1*WORD_WIDTH);
  u_dds : nco
  generic map(
    WW         => WORD_WIDTH,
    STAGES     => WORD_WIDTH,
    FRAC_BITS  => WORD_WIDTH-1,
    MAGNITUDE  => 1.0,
    RESET_ACTIVE_LEVEL => '1'
  )
  port map(
    Clock => clk_i,
    Reset => srst_i,
    Angle => angle_s,
    Sin   => pll_sin_s,
    Cos   => pll_cos_s
  );

  os_sin_o <= std_logic_vector(pll_sin_s);
  os_cos_o <= std_logic_vector(pll_cos_s);

end architecture rtl;


