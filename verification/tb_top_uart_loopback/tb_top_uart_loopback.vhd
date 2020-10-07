-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

library work;
use work.pkg_edu_bbt.all;

-- entity
entity tb_top_uart_loopback is
end entity tb_top_uart_loopback;

-- architecture
architecture rtl of tb_top_uart_loopback is

  -- signals
  signal tb_dut_clk_i      : std_logic := '1';                   
  -- signal tb_dut_en_i       : std_logic;                    
  signal tb_dut_arst_i     : std_logic;                   
  signal tb_dut_rx_i       : std_logic;                   
  signal tb_dut_tx_o       : std_logic;                   
  -- signal tb_dut_is_data_i  : std_logic_vector(7 downto 0);                            
  -- signal tb_dut_is_dv_i    : std_logic;
  -- signal tb_dut_is_rfd_o   : std_logic;
  -- signal tb_dut_os_data_o  : std_logic_vector(7 downto 0);                            
  -- signal tb_dut_os_dv_o    : std_logic;
  -- signal tb_dut_os_rfd_i   : std_logic;
  -- signal tb_dut_tx_rdy_o   : std_logic;
  -- signal tb_dut_rx_ovf_o   : std_logic;

  signal tb_clock_counter_s : unsigned(31 downto 0) := X"00000000";
  -- signal os_dv_delay_s      : std_logic_vector(8 downto 0);
  -- signal dut_os_dv_d1_s     : std_logic;
  -- signal dut_os_dv_flank_s  : std_logic;
  signal tb_uart_arst     : std_logic;
  signal tb_uart_tx       : std_logic;
  signal tb_uart_tx_en    : std_logic;
  signal tb_uart_tx_data  : std_logic_vector(7 downto 0);
  signal tb_uart_rx       : std_logic;
  signal tb_uart_rx_busy  : std_logic;
  signal tb_uart_rx_error : std_logic;
  signal tb_uart_rx_data  : std_logic_vector(7 downto 0);
  signal tb_uart_tx_busy  : std_logic;

  constant SAMPLE_PERIOD   : time    := 62500 ps;
  -- constant N_TX            : integer := 2;
  -- constant N_ZEROS         : integer := 123;
                             
begin

  ------------------------------------------------------------
  -- Clock counter (DEBUG)
  u_clk_counter : process(tb_dut_clk_i)
  begin
    if rising_edge(tb_dut_clk_i) then
      tb_clock_counter_s <= tb_clock_counter_s + 1;
    end if;
  end process;
  ------------------------------------------------------------

  ------------------------------------------------------------
  -- BEGIN DUT
  ------------------------------------------------------------
  tb_dut_rx_i <= tb_uart_tx;
  u_dut : top_uart_loopback
  port map
  (
    clk_i  => tb_dut_clk_i,
    arst_i => tb_dut_arst_i,
    rx_i   => tb_dut_rx_i,
    tx_o   => tb_dut_tx_o
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
    variable l      : line;
  begin
    tb_dut_arst_i     <= '1';
    tb_uart_tx_data   <= "00000000";
    tb_uart_tx_en     <= '0';
    wait for 3*SAMPLE_PERIOD;
    tb_dut_arst_i     <= '0';
    wait for 10*SAMPLE_PERIOD;
    --
    -- send XFF
    if tb_uart_tx_busy = '1' then
      wait until tb_uart_tx_busy = '0';
    end if;
    tb_uart_tx_data   <= X"FF";
    wait for 100*SAMPLE_PERIOD;
    tb_uart_tx_en     <= '1';
    wait for 1*SAMPLE_PERIOD;
    tb_uart_tx_en     <= '0';
    wait for 1*SAMPLE_PERIOD;
    -- send X00
    if tb_uart_tx_busy = '1' then
      wait until tb_uart_tx_busy = '0';
    end if;
    tb_uart_tx_data   <= X"00";
    wait for 100*SAMPLE_PERIOD;
    tb_uart_tx_en     <= '1';
    wait for 1*SAMPLE_PERIOD;
    tb_uart_tx_en     <= '0';
    wait for 1*SAMPLE_PERIOD;
    -- wait until tx_ready = '1'
    if tb_uart_tx_busy = '1' then
      wait until tb_uart_tx_busy = '0';
    end if;
    tb_uart_tx_data   <= X"FF";
    --
    wait for 16*MODEM_CLK_FREQ/UART_BAUD_RATE*SAMPLE_PERIOD;
    --
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
    wait;
  end process;
  ------------------------------------------------------------
  -- END STIMULUS
  ------------------------------------------------------------

  -- UART
  tb_uart_rx   <= '1';
  tb_uart_arst <= not(tb_dut_arst_i);
  u_tb_uart : uart
  generic map
  (
    clk_freq  => MODEM_CLK_FREQ, --frequency of system clock in Hertz
    baud_rate => UART_BAUD_RATE, --data link baud rate in bits/second
    os_rate   => 16,             --oversampling rate to find center of receive bits (in samples per baud period)
    d_width   => 8,              --data bus width
    parity    => 0,              --0 for no parity, 1 for parity
    parity_eo => '0'             --'0' for even, '1' for odd parity
  )
  port map
  (
    clk       => tb_dut_clk_i,     --system clock
    reset_n   => tb_uart_arst,     --ascynchronous reset
    tx_ena    => tb_uart_tx_en,    --initiate transmission
    tx_data   => tb_uart_tx_data,  --data to transmit
    rx        => tb_uart_tx,       --receive pin
    rx_busy   => tb_uart_rx_busy,  --data reception in progress
    rx_error  => tb_uart_rx_error, --start, parity, or stop bit error detected
    rx_data   => tb_uart_rx_data,  --data received
    tx_busy   => tb_uart_tx_busy,  --transmission in progress
    tx        => tb_uart_tx        --transmit pin
  );

end architecture;



