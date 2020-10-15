--------------------------------------------------------------------------------
-- TODO
--------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;

entity sif_uart is
  generic (
    CLK_FREQ  : integer   := 100_000_000; -- frequency of system clock in Hertz
    BAUD_RATE : integer   := 115_200;     -- data link baud rate in bits/second
    OS_RATE   : integer   := 16;          -- oversampling rate to find center of receive bits (in samples per baud period)
    D_WIDTH   : integer   := 8;           -- data bus width
    PARITY    : integer   := 1;           -- 0 for no parity, 1 for parity
    PARITY_EO : std_logic := '0'          -- '0' for even, '1' for odd parity
  );
  port (
    -- clk, srst
    clk_i        : in  std_logic;
    srst_i       : in  std_logic;
    -- Serial Interface
    rx_i         : in  std_logic;
    tx_o         : out std_logic;
    -- Input Stream Interface
    tx_is_data_i : in  std_logic_vector(7 downto 0);
    tx_is_dv_i   : in  std_logic;
    tx_is_rfd_o  : out std_logic;
    -- Output Stream Interface
    rx_os_data_o : out std_logic_vector(7 downto 0);
    rx_os_dv_o   : out std_logic;
    rx_os_rfd_i  : in  std_logic;
    -- Status
    rx_err_o     : out std_logic;
    rx_ovf_o     : out std_logic
  );
end entity sif_uart;
    
architecture rtl of sif_uart is

  component uart IS
    GENERIC(
      clk_freq  :  INTEGER    := 50_000_000;  --frequency of system clock in Hertz
      baud_rate  :  INTEGER    := 19_200;    --data link baud rate in bits/second
      os_rate    :  INTEGER    := 16;      --oversampling rate to find center of receive bits (in samples per baud period)
      d_width    :  INTEGER    := 8;       --data bus width
      parity    :  INTEGER    := 1;        --0 for no parity, 1 for parity
      parity_eo  :  STD_LOGIC  := '0');      --'0' for even, '1' for odd parity
    PORT(
      clk      :  IN    STD_LOGIC;                    --system clock
      reset_n  :  IN    STD_LOGIC;                    --ascynchronous reset
      tx_ena  :  IN    STD_LOGIC;                    --initiate transmission
      tx_data  :  IN    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
      rx      :  IN    STD_LOGIC;                    --receive pin
      rx_busy  :  OUT  STD_LOGIC;                    --data reception in progress
      rx_error  :  OUT  STD_LOGIC;                    --start, parity, or stop bit error detected
      rx_data  :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data received
      tx_busy  :  OUT  STD_LOGIC;                    --transmission in progress
      tx      :  OUT  STD_LOGIC);                    --transmit pin
  end component uart;

  -- Signals
  signal srst_n_s           : std_logic;
  signal tx_data_s          : std_logic_vector(7 downto 0);
  signal tx_busy_s          : std_logic;
  signal tx_en_s            : std_logic;
  signal rx_data_s          : std_logic_vector(7 downto 0);
  signal rx_busy_s          : std_logic;
  signal rx_busy_d1_s       : std_logic;
  signal rx_os_dv_s         : std_logic;
  signal uart_new_rx_data_s : std_logic;

begin

  -- UART Module
  u_uart : uart
  generic map
  (
    clk_freq  => CLK_FREQ, --frequency of system clock in Hertz
    baud_rate => BAUD_RATE, --data link baud rate in bits/second
    os_rate   => 16,             --oversampling rate to find center of receive bits (in samples per baud period)
    d_width   => 8,              --data bus width
    parity    => 0,              --0 for no parity, 1 for parity
    parity_eo => '0'             --'0' for even, '1' for odd parity
  )
  port map
  (
    clk       => clk_i,     --system clock
    reset_n   => srst_n_s,  --ascynchronous reset
    tx_ena    => tx_en_s,   --initiate transmission
    tx_data   => tx_data_s, --data to transmit
    rx        => rx_i,      --receive pin
    rx_busy   => rx_busy_s, --data reception in progress
    rx_error  => open,      --start, parity, or stop bit error detected
    rx_data   => rx_data_s, --data received
    tx_busy   => tx_busy_s, --transmission in progress
    tx        => tx_o       --transmit pin
  );
  srst_n_s <= not(srst_i);
  -- UART RX Interface
  u_uart_rx_bysy_flank : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
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
      if srst_i = '1' then
        rx_os_data_o <= (others => '0');
        rx_os_dv_s    <= '0';
        rx_ovf_o   <= '0';
      else
        if uart_new_rx_data_s = '1' then
          rx_os_data_o  <= rx_data_s;
          rx_os_dv_s    <= '1';
        end if;
        if rx_os_rfd_i = '1' and rx_os_dv_s = '1' then
          rx_os_dv_s    <= '0';
        end if;
        if rx_os_rfd_i = '0' and rx_os_dv_s = '1' and uart_new_rx_data_s = '1' then
          rx_ovf_o <= '1';
        end if;
      end if;
    end if;
  end process;
  rx_os_dv_o <= rx_os_dv_s;

  -- UART TX Interface
  tx_data_s      <= tx_is_data_i;
  tx_en_s        <= tx_is_dv_i and not(tx_busy_s);
  tx_is_rfd_o <= not(tx_busy_s);

end architecture rtl;
