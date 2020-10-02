-- libraries
library ieee;
use ieee.std_logic_1164.all;

-- Package Declaration Section
package pkg_edu_bbt is

  constant SYS_CLK_FREQ   : natural := 125_000_000;
  constant UART_BAUD_RATE : natural := 115200;

  component top_uart_loopback is
    port(
      clk_i   : in  std_logic;                    --system clock
      arst_i  : in  std_logic;                    --ascynchronous reset
      rx_i    : in  std_logic;                    --receive pin
      tx_o    : out std_logic
    );
  end component top_uart_loopback;

  component uart is
    generic(
      clk_freq  : integer    := 50_000_000;  --frequency of system clock in Hertz
      baud_rate : integer    := 19_200;      --data link baud rate in bits/second
      os_rate   : integer    := 16;          --oversampling rate to find center of receive bits (in samples per baud period)
      d_width   : integer    := 8;           --data bus width
      parity    : integer    := 1;           --0 for no parity, 1 for parity
      parity_eo : std_logic  := '0');        --'0' for even, '1' for odd parity
    port(
      clk       : in  std_logic;                             --system clock
      reset_n   : in  std_logic;                             --ascynchronous reset
      tx_ena    : in  std_logic;                             --initiate transmission
      tx_data   : in  std_logic_vector(d_width-1 downto 0);  --data to transmit
      rx        : in  std_logic;                             --receive pin
      rx_busy   : out std_logic;                             --data reception in progress
      rx_error  : out std_logic;                             --start, parity, or stop bit error detected
      rx_data   : out std_logic_vector(d_width-1 downto 0);  --data received
      tx_busy   : out std_logic;                             --transmission in progress
      tx        : out std_logic);                            --transmit pin
  end component uart;

  component simple_fifo is
    generic (
      RESET_ACTIVE_LEVEL : std_ulogic := '1';
      MEM_SIZE           : positive;
      SYNC_READ          : boolean    := true
      );
    port (
      Clock   : in std_ulogic;
      Reset   : in std_ulogic;
      We      : in std_ulogic;  --# Write enable
      Wr_data : in std_ulogic_vector;
      Re      : in  std_ulogic;
      Rd_data : out std_ulogic_vector;
      Empty : out std_ulogic;
      Full  : out std_ulogic;
      Almost_empty_thresh : in  natural range 0 to MEM_SIZE-1 := 1;
      Almost_full_thresh  : in  natural range 0 to MEM_SIZE-1 := 1;
      Almost_empty        : out std_ulogic;
      Almost_full         : out std_ulogic
      );
  end component;

  component dual_port_ram is
    generic (
      MEM_SIZE  : positive;
      SYNC_READ : boolean := true
    );
    port (
      Wr_clock : in std_ulogic;
      We       : in std_ulogic; -- Write enable
      Wr_addr  : in natural range 0 to MEM_SIZE-1;
      Wr_data  : in std_ulogic_vector;
      Rd_clock : in std_ulogic;
      Re       : in std_ulogic; -- Read enable
      Rd_addr  : in natural range 0 to MEM_SIZE-1;
      Rd_data  : out std_ulogic_vector
    );
  end component;
  
end package pkg_edu_bbt;
