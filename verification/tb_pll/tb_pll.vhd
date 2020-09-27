-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entity
entity tb_pll is
end entity tb_pll;

-- architecture
architecture rtl of tb_pll is

  component pll is
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
      -- Output Stream
      os_sin_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
      os_cos_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
      -- Config       
      freq_zqero_i    : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      pll_kp_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      pll_ki_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      -- State        
      phase_err_o     : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      phase_int_err_o : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      phase_o         : in  std_logic_vector(WORD_WIDTH-1 downto 0)
    );
  end component pll;

  component nco is
    generic (
      WW         : positive;       -- Width of parameters
      STAGES     : positive; -- Number of CORDIC iterations
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

  -- signals
  signal tb_dut_clk_i      : std_logic := '1';                   
  signal tb_dut_en_i       : std_logic;                    
  signal tb_dut_srst_i     : std_logic;                   
  signal tb_dut_is_data_i  : std_logic_vector(7 downto 0);                            
  signal tb_dut_is_dv_i    : std_logic;
  signal tb_dut_is_rfd_o   : std_logic;
  signal tb_dut_os_data_o  : std_logic_vector(9 downto 0);                            
  signal tb_dut_os_dv_o    : std_logic;
  signal tb_dut_os_rfd_i   : std_logic;
  signal tb_dut_send_i     : std_logic;
  signal tb_dut_tx_rdy_o   : std_logic;

  constant SAMPLE_PERIOD   : time    := 62500 ps;
  constant N_TX            : integer := 5;
  constant N_ZEROS         : integer := 123;

  signal tb_phase_s        : std_logic_vector(9 downto 0);
  signal sin_s             : signed(9 downto 0);
  signal cos_s             : signed(9 downto 0);

  signal pll_cos_s             : std_logic_vector(9 downto 0);
  signal pll_sin_s             : std_logic_vector(9 downto 0);
  signal pll_phase_err_s       : std_logic_vector(9 downto 0);
  signal pll_phase_int_err_s   : std_logic_vector(9 downto 0);
  signal pll_phase_s           : std_logic_vector(9 downto 0);

  constant tb_freq_s         : integer := 16;
                             
begin

  -- phase
  process(tb_dut_clk_i)
  begin
    if rising_edge(tb_dut_clk_i) then
      if tb_dut_srst_i = '1' then
        tb_phase_s <= (others => '0');
      else
        tb_phase_s <= std_logic_vector(unsigned(tb_phase_s) + tb_freq_s);
      end if;
    end if;
  end process;

  -- nco
  u_dds : nco
  generic map(
    WW         => 10,
    STAGES     => 10,
    FRAC_BITS  => 10-1,
    MAGNITUDE  => 1.0,
    RESET_ACTIVE_LEVEL => '1'
  )
  port map(
    Clock => tb_dut_clk_i,
    Reset => tb_dut_srst_i,
    Angle => signed(tb_phase_s),
    Sin   => sin_s,
    Cos   => cos_s
  );

  ------------------------------------------------------------
  -- BEGIN DUT
  ------------------------------------------------------------
  dut : pll
  generic map(WORD_WIDTH => 10)
  port map(
    -- clk, en, rst
    clk_i           => tb_dut_clk_i,
    en_i            => tb_dut_en_i,
    srst_i          => tb_dut_srst_i,
    -- Input Stream
    is_data_i       => std_logic_vector(cos_s),
    -- Output Stream
    os_sin_o        => pll_sin_s,
    os_cos_o        => pll_cos_s,
    -- Config
    freq_zqero_i    => std_logic_vector(to_unsigned(tb_freq_s+2,10)),
    pll_kp_i        => "00"&"0100"&"0000",
    pll_ki_i        => "00"&"0001"&"0000",
    -- State
    phase_err_o     => pll_phase_err_s,
    phase_int_err_o => pll_phase_int_err_s,
    phase_o         => pll_phase_s
  );
  ------------------------------------------------------------
  -- END DUT
  ------------------------------------------------------------


  ------------------------------------------------------------
  -- BEGIN STIMULUS
  ------------------------------------------------------------
  -- clock
  tb_dut_clk_i <= not tb_dut_clk_i after SAMPLE_PERIOD/2;
  --
  --
  -- Enable and reset Stimulus
  -- Signals:
  -- * tb_dut_en_i
  -- * tb_dut_srst_i
  process
  begin
    tb_dut_en_i       <= '1';
    tb_dut_srst_i     <= '1';
    wait for 3*SAMPLE_PERIOD;
    tb_dut_en_i       <= '1';
    tb_dut_srst_i     <= '0';
    wait;
  end process;
  --
  --
  -- Control Stimulus
  -- Signals:
  -- * tb_dut_send_i
  process
    variable l      : line;
  begin
    wait for 800 us;
    -- END OF SIMULATION
    write(l,string'("                                 ")); writeline(output,l);
    write(l,string'("#################################")); writeline(output,l);
    write(l,string'("#                               #")); writeline(output,l);
    write(l,string'("#  ++====    ++\  ++    ++=\\   #")); writeline(output,l);
    write(l,string'("#  ||        ||\\ ||    ||  \\  #")); writeline(output,l);
    write(l,string'("#  ||===     || \\||    ||  ||  #")); writeline(output,l);
    write(l,string'("#  ||        ||  \||    ||  //  #")); writeline(output,l);
    write(l,string'("#  ++====    ++   ++    ++=//   #")); writeline(output,l);
    write(l,string'("#                               #")); writeline(output,l);
    write(l,string'("#################################")); writeline(output,l);
    write(l,string'("                                 ")); writeline(output,l);
    assert false -- este assert se pone para abortar la simulacion
      report "Fin de la simulacion"
      severity failure;
  end process;
  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

end architecture;




