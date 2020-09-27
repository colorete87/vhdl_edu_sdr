-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entity
entity tb_test_modem_channel is
end entity tb_test_modem_channel;

-- architecture
architecture rtl of tb_test_modem_channel is

  -- components
  component test_modem_channel is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(7 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(7 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic;
      -- Others
      tx_rdy_o      : out std_logic
    );
  end component test_modem_channel;

  -- signals
  signal tb_dut_clk_i      : std_logic := '1';                   
  signal tb_dut_en_i       : std_logic;                    
  signal tb_dut_srst_i     : std_logic;                   
  signal tb_dut_is_data_i  : std_logic_vector(7 downto 0);                            
  signal tb_dut_is_dv_i    : std_logic;
  signal tb_dut_is_rfd_o   : std_logic;
  signal tb_dut_os_data_o  : std_logic_vector(7 downto 0);                            
  signal tb_dut_os_dv_o    : std_logic;
  signal tb_dut_os_rfd_i   : std_logic;
  signal tb_dut_tx_rdy_o   : std_logic;

  constant SAMPLE_PERIOD   : time    := 62500 ps;
  constant N_TX            : integer := 3;
  constant N_ZEROS         : integer := 123;
                             
begin

  ------------------------------------------------------------
  -- BEGIN DUT
  ------------------------------------------------------------
  dut : test_modem_channel
  port map (
    -- clk, en, rst
    clk_i         => tb_dut_clk_i,
    en_i          => tb_dut_en_i,
    srst_i        => tb_dut_srst_i,
    -- Input Stream
    is_data_i     => tb_dut_is_data_i,
    is_dv_i       => tb_dut_is_dv_i,
    is_rfd_o      => tb_dut_is_rfd_o,
    -- Output Stream
    os_data_o     => tb_dut_os_data_o,
    os_dv_o       => tb_dut_os_dv_o,
    os_rfd_i      => tb_dut_os_rfd_i,
    -- Others
    tx_rdy_o      => tb_dut_tx_rdy_o
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
  -- Input Stream Stimulus
  -- Signals:
  -- * tb_dut_is_data_i
  -- * tb_dut_is_dv_i
  tb_dut_is_dv_i   <= '1';
  process (tb_dut_clk_i)
    variable i_v    : integer := 0;
    variable byte_v : integer := 255;
    variable l      : line;
  begin
    tb_dut_is_data_i <= std_logic_vector(to_unsigned(byte_v,8));
    if rising_edge(tb_dut_clk_i) then
      if tb_dut_is_rfd_o = '1' then
        report "[INFO] Byte número:" & integer'image(i_v);
        i_v    := i_v+1;
        byte_v := byte_v-1;
      end  if;
    end if;
    if i_v >= N_TX*4 and tb_dut_tx_rdy_o = '1' then
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
        report "[INFO] Fin de la simulacion"
        severity failure;
    end if;
  end process;
  --
  --
  -- Output Stream Stimulus
  -- Signals:
  -- * tb_dut_os_rfd_i
  process
  begin
    tb_dut_os_rfd_i   <= '1';
    wait;
  end process;
  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

end architecture;



