-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Package Declaration Section
package pkg_edu_bbt is

  -- constant MODEM_CLK_FREQ : natural := 125_000_000;
  -- constant MODEM_CLK_FREQ : natural := 50_000_000;
  constant MODEM_CLK_FREQ : natural := 16_000_000;
  constant UART_BAUD_RATE : natural := 115200;

  component top_uart_loopback is
    port(
      clk_i   : in  std_logic;                    --system clock
      arst_i  : in  std_logic;                    --ascynchronous reset
      rx_i    : in  std_logic;                    --receive pin
      tx_o    : out std_logic
    );
  end component top_uart_loopback;

  component top_edu_bbt is
    port(
      clk_i              : in  std_logic;                    --system clock
      arst_i             : in  std_logic;                    --ascynchronous reset
      rx_i               : in  std_logic;                    --receive pin
      tx_o               : out std_logic;                    --transmit pin
      -- Config
      nm1_bytes_i        : in std_logic_vector( 7 downto 0);
      nm1_pre_i          : in std_logic_vector( 7 downto 0);
      nm1_sfd_i          : in std_logic_vector( 7 downto 0);
      det_th_i           : in std_logic_vector(15 downto 0);
      pll_kp_i           : in std_logic_vector(15 downto 0);
      pll_ki_i           : in std_logic_vector(15 downto 0);
      -- Modem to channel
      mod_os_data_o      : out std_logic_vector( 9 downto 0);
      mod_os_dv_o        : out std_logic;
      mod_os_rfd_i       : in  std_logic;
      -- Channel to Modem
      chan_os_data_i     : in  std_logic_vector( 9 downto 0);
      chan_os_dv_i       : in  std_logic;
      chan_os_rfd_o      : out std_logic
    );
  end component top_edu_bbt;

  component bb_modem is
    port
    (
      -- clk, en, rst
      clk_i            : in  std_logic;
      en_i             : in  std_logic;
      srst_i           : in  std_logic;
      -- Input Stream
      is_data_i        : in  std_logic_vector(7 downto 0);
      is_dv_i          : in  std_logic;
      is_rfd_o         : out std_logic;
      -- Output Stream
      os_data_o        : out std_logic_vector(7 downto 0);
      os_dv_o          : out std_logic;
      os_rfd_i         : in  std_logic;
      -- DAC Stream
      dac_os_data_o    : out std_logic_vector(9 downto 0);
      dac_os_dv_o      : out std_logic;
      dac_os_rfd_i     : in  std_logic;
      -- ADC Stream
      adc_is_data_i    : in  std_logic_vector(9 downto 0);
      adc_is_dv_i      : in  std_logic;
      adc_is_rfd_o     : out std_logic;
      -- Config
      nm1_bytes_i      : in  std_logic_vector(7 downto 0);
      nm1_pre_i        : in  std_logic_vector(7 downto 0);
      nm1_sfd_i        : in  std_logic_vector(7 downto 0);
      det_th_i         : in  std_logic_vector(15 downto 0);
      pll_kp_i         : in  std_logic_vector(15 downto 0);
      pll_ki_i         : in  std_logic_vector(15 downto 0);
      -- Control    
      send_i           : in  std_logic;
      -- State      
      tx_rdy_o         : out std_logic;
      rx_ovf_o         : out std_logic
    );
  end component bb_modem;

  component bb_channel is
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
      os_data_o     : out std_logic_vector( 9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic;
      -- Control
      sigma_i       : in  std_logic_vector(15 downto 0)
    );
  end component bb_channel;

  component sif_uart is
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
  end component sif_uart;

  component sif_fifo is
    generic (
      RESET_ACTIVE_LEVEL : std_logic := '1';
      MEM_SIZE           : positive;
      SYNC_READ          : boolean    := true
    );
    port (
      -- clk, srst
      clk_i        : in  std_logic;
      srst_i       : in  std_logic;
      -- Input Stream Interface
      is_data_i    : in  std_logic_vector(7 downto 0);
      is_dv_i      : in  std_logic;
      is_rfd_o     : out std_logic;
      -- Output Stream Interface
      os_data_o    : out std_logic_vector(7 downto 0);
      os_dv_o      : out std_logic;
      os_rfd_i     : in  std_logic;
      -- Status
      empty_o      : out std_logic;
      full_o       : out std_logic;
      data_count_o : out std_logic_vector(integer(ceil(log2(real(MEM_SIZE))))-1 downto 0)
    );
  end component sif_fifo;
      
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
      RESET_ACTIVE_LEVEL : std_logic := '1';
      MEM_SIZE           : positive;
      SYNC_READ          : boolean    := true
      );
    port (
      Clock        : in  std_logic;
      Reset        : in  std_logic;
      We           : in  std_logic;  --# Write enable
      Wr_data      : in  std_logic_vector;
      Re           : in  std_logic;
      Rd_data      : out std_logic_vector;
      Empty        : out std_logic;
      Full         : out std_logic;
      data_count_o : out std_logic_vector(integer(ceil(log2(real(MEM_SIZE))))-1 downto 0)
      );
  end component;

  component dual_port_ram is
    generic (
      MEM_SIZE  : positive;
      SYNC_READ : boolean := true
    );
    port (
      Wr_clock : in std_logic;
      We       : in std_logic; -- Write enable
      Wr_addr  : in natural range 0 to MEM_SIZE-1;
      Wr_data  : in std_logic_vector;
      Rd_clock : in std_logic;
      Re       : in std_logic; -- Read enable
      Rd_addr  : in natural range 0 to MEM_SIZE-1;
      Rd_data  : out std_logic_vector
    );
  end component;
  
end package pkg_edu_bbt;
