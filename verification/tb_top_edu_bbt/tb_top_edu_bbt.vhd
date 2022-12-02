-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

library work;
use work.pkg_edu_bbt.all;

-- entity
entity tb_top_edu_bbt is
end entity tb_top_edu_bbt;

-- architecture
architecture rtl of tb_top_edu_bbt is

  -- signals
  signal tb_dut_clk_i      : std_logic := '1';
  signal tb_dut_arst_i     : std_logic;
  signal tb_dut_rx_i       : std_logic;
  signal tb_dut_tx_o       : std_logic;

  signal tb_clock_counter_s : unsigned(31 downto 0) := X"00000000";
  signal tb_uart_arst     : std_logic;
  signal tb_uart_tx       : std_logic;
  signal tb_uart_tx_en    : std_logic;
  signal tb_uart_tx_data  : std_logic_vector(7 downto 0);
  signal tb_uart_rx       : std_logic;
  signal tb_uart_rx_busy  : std_logic;
  signal tb_uart_rx_error : std_logic;
  signal tb_uart_rx_data  : std_logic_vector(7 downto 0);
  signal tb_uart_tx_busy  : std_logic;

  constant SYS_CLK_FREQ   : natural := 125_000_000;

  constant SAMPLE_PERIOD   : time    := 62500 ps;

  -- Modulator to channel output
  signal mod_os_data_s  : std_logic_vector( 9 downto 0);
  signal mod_os_dv_s    : std_logic;
  signal mod_os_rfd_s   : std_logic;
  -- Channel output
  signal chan_os_data_s : std_logic_vector( 9 downto 0);
  signal chan_os_dv_s   : std_logic;
  signal chan_os_rfd_s  : std_logic;

  -- Modem config
  constant nm1_bytes_c  : std_logic_vector( 7 downto 0) := X"03";
  constant nm1_pre_c    : std_logic_vector( 7 downto 0) := X"07";
  constant nm1_sfd_c    : std_logic_vector( 7 downto 0) := X"03";
  constant det_th_c     : std_logic_vector(15 downto 0) := X"0040";
  constant pll_kp_c     : std_logic_vector(15 downto 0) := X"A000";
  constant pll_ki_c     : std_logic_vector(15 downto 0) := X"9000";
  -- Channel config
  constant sigma_c      : std_logic_vector(15 downto 0) := X"0040"; -- QU16.12

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
  tb_uart_rx <= tb_dut_tx_o;
  u_dut : top_edu_bbt
  port map
  (
    clk_i  => tb_dut_clk_i,
    arst_i => tb_dut_arst_i,
    rx_i   => tb_dut_rx_i,
    tx_o   => tb_dut_tx_o,
    -- Config
    nm1_bytes_i => nm1_bytes_c,
    nm1_pre_i   => nm1_pre_c,
    nm1_sfd_i   => nm1_sfd_c,
    det_th_i    => det_th_c,
    pll_kp_i    => pll_kp_c,
    pll_ki_i    => pll_ki_c,
    -- Modem to channel
    mod_os_data_o => mod_os_data_s,
    mod_os_dv_o   => mod_os_dv_s,
    mod_os_rfd_i  => mod_os_rfd_s,
    -- Channel to Modem
    chan_os_data_i => chan_os_data_s,
    chan_os_dv_i   => chan_os_dv_s,
    chan_os_rfd_o  => chan_os_rfd_s
  );
  ------------------------------------------------------------
  u_channel : bb_channel
  port map
  (
    -- clk, en, rst
    clk_i         => tb_dut_clk_i,
    en_i          => '1',
    srst_i        => tb_dut_arst_i,
    -- Input Stream
    is_data_i     => mod_os_data_s,
    is_dv_i       => mod_os_dv_s,
    is_rfd_o      => mod_os_rfd_s,
    -- Output Stream
    os_data_o     => chan_os_data_s,
    os_dv_o       => chan_os_dv_s,
    os_rfd_i      => chan_os_rfd_s,
    -- Control
    sigma_i       => sigma_c
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
  -- TODO
  process
    variable l      : line;
  begin
    tb_dut_arst_i     <= '1';
    tb_uart_tx_data   <= X"FF";
    tb_uart_tx_en     <= '0';
    wait for 3*SAMPLE_PERIOD;
    tb_dut_arst_i     <= '0';
    wait for 10*SAMPLE_PERIOD;
    --
    for i in 1 to 8 loop
      -- send 0xFF
      if tb_uart_tx_busy = '1' then
        wait until tb_uart_tx_busy = '0';
      end if;
      wait for 16*2*SAMPLE_PERIOD;
      tb_uart_tx_data   <= not(tb_uart_tx_data);
      -- tb_uart_tx_data   <= std_logic_vector(unsigned(tb_uart_tx_data)+1);
      wait for 1*SAMPLE_PERIOD;
      tb_uart_tx_en     <= '1';
      wait for 1*SAMPLE_PERIOD;
      tb_uart_tx_en     <= '0';
      wait for 1*SAMPLE_PERIOD;
    end loop;
    wait for 16*200*SAMPLE_PERIOD;
    if tb_uart_tx_busy = '1' then
      wait until tb_uart_tx_busy = '0';
    end if;
    tb_uart_tx_data   <= X"FF";
    --
    wait for 4*8*MODEM_CLK_FREQ/UART_BAUD_RATE*SAMPLE_PERIOD;
    --
    wait for 16*(8+4+4*8)*SAMPLE_PERIOD;
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
  --tb_uart_rx   <= '1';
  tb_uart_arst <= not(tb_dut_arst_i);
  -- uart log
  u_uart_log : process(tb_dut_clk_i)
    variable tx_byte_num_v    : integer := 0;
    variable rx_byte_num_v    : integer := 0;
    variable last_tx_en_v     : std_logic := '0';
    variable last_rx_busy_v   : std_logic := '0';
  begin
    if rising_edge(tb_dut_clk_i) then
      if tb_uart_tx_en = '1' and last_tx_en_v = '0' then
        report "[INFO] TX Byte[" & integer'image(tx_byte_num_v) & "] = " & integer'image(to_integer(unsigned(tb_uart_tx_data)));
        -- report std_logic_vector'image(tb_uart_tx_data);
        tx_byte_num_v := tx_byte_num_v + 1;
      end if;
      if tb_uart_rx_busy = '0' and last_rx_busy_v = '1' then
        report "[INFO] RX Byte[" & integer'image(rx_byte_num_v) & "] = " & integer'image(to_integer(unsigned(tb_uart_rx_data)));
        -- report std_logic_vector'image(tb_uart_rx_data);
        rx_byte_num_v := rx_byte_num_v + 1;
      end if;
      --if tb_uart_rx_error = '1' then
      --  report "[INFO] RX ERROR!!!";
      --    -- severity failure;
      --end if;
      last_tx_en_v   := tb_uart_tx_en;
      last_rx_busy_v := tb_uart_rx_busy;
    end if;
  end process;
  -- uart module
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
    rx        => tb_uart_rx,       --receive pin
    rx_busy   => tb_uart_rx_busy,  --data reception in progress
    rx_error  => tb_uart_rx_error, --start, parity, or stop bit error detected
    rx_data   => tb_uart_rx_data,  --data received
    tx_busy   => tb_uart_tx_busy,  --transmission in progress
    tx        => tb_uart_tx        --transmit pin
  );

end architecture;



