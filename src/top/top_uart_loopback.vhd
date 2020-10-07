-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_edu_bbt.all;

-- entity
entity top_uart_loopback is
  port(
    clk_i   : in  std_logic;                    --system clock
    arst_i  : in  std_logic;                    --ascynchronous reset
    rx_i    : in  std_logic;                    --receive pin
    tx_o    : out std_logic
  );
end entity top_uart_loopback;

-- architecture
architecture rtl of top_uart_loopback is


  signal arst_n_s     : std_logic;
  signal srst_n_s     : std_logic;
  signal srst_s       : std_logic;
  signal tx_data_s    : std_logic_vector(7 downto 0);
  signal tx_busy_s    : std_logic;
  signal tx_en_s      : std_logic;
  signal rx_data_s    : std_logic_vector(7 downto 0);
  signal rx_busy_s    : std_logic;
  signal rx_busy_d1_s : std_logic;

  signal uart_os_data_s     : std_logic_vector(7 downto 0);
  signal uart_os_dv_s       : std_logic;
  signal uart_os_rfd_s      : std_logic;
  signal uart_is_data_s     : std_logic_vector(7 downto 0);
  signal uart_is_dv_s       : std_logic;
  signal uart_is_rfd_s      : std_logic;
  signal uart_rx_ovf_o      : std_logic;
  signal uart_new_rx_data_s : std_logic;

begin

  -- Generate synchronous reset
  arst_n_s <= not(arst_i);
  srst_n_s <= not(srst_s);
  u_srst : process(clk_i)
  begin
    if rising_edge(clk_i) then
      srst_s <= arst_i;
    end if;
  end process;

  -- UART
  u_uart : uart
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
    clk       => clk_i,      --system clock
    reset_n   => srst_n_s,   --ascynchronous reset
    tx_ena    => tx_en_s,    --initiate transmission
    tx_data   => tx_data_s,  --data to transmit
    rx        => rx_i,       --receive pin
    rx_busy   => rx_busy_s,  --data reception in progress
    rx_error  => open,       --start, parity, or stop bit error detected
    rx_data   => rx_data_s,  --data received
    tx_busy   => tx_busy_s,  --transmission in progress
    tx        => tx_o        --transmit pin
  );

  -- UART RX Interface
  u_uart_rx_bysy_flank : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_s = '1' then
        rx_busy_d1_s <= '0';
      else
        rx_busy_d1_s <= rx_busy_s;
      end if;
    end if;
  end process;
  uart_new_rx_data_s <= not(rx_busy_s) and rx_busy_d1_s;
  u_uart_rx_if : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_s = '1' then
        uart_os_data_s <= (others => '0');
        uart_os_dv_s    <= '0';
        uart_rx_ovf_o   <= '0';
      else
        if uart_new_rx_data_s = '1' then
          uart_os_data_s  <= rx_data_s;
          uart_os_dv_s    <= '1';
        end if;
        if uart_os_rfd_s = '1' and uart_os_dv_s = '1' then
          uart_os_dv_s    <= '0';
        end if;
        if uart_os_rfd_s = '0' and uart_os_dv_s = '1' and uart_new_rx_data_s = '1' then
          uart_rx_ovf_o <= '1';
        end if;
      end if;
    end if;
  end process;

  -- UART TX Interface
  tx_data_s     <= std_logic_vector(unsigned(uart_is_data_s)+1);
  tx_en_s       <= uart_is_dv_s and not(tx_busy_s);
  uart_is_rfd_s <= not(tx_busy_s);

  -- UART loopback
  uart_is_data_s  <= uart_os_data_s;
  uart_is_dv_s    <= uart_os_dv_s;
  uart_os_rfd_s   <= uart_is_rfd_s;

end architecture;
