-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_edu_bbt.all;

-- entity
entity top_edu_bbt is
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
end entity top_edu_bbt;

-- architecture
architecture rtl of top_edu_bbt is

  ------------------------------------------------------------------------------
  -- SIGNALS
  ------------------------------------------------------------------------------
  -- UART signals
  signal arst_n_s     : std_logic;
  signal srst_s       : std_logic := '1';

  -- UART IF signals
  signal uart_os_data_s     : std_logic_vector(7 downto 0);
  signal uart_os_dv_s       : std_logic;
  signal uart_os_rfd_s      : std_logic;
  signal uart_rx_err_s      : std_logic;
  signal uart_rx_ovf_s      : std_logic;

  -- Modem Control
  signal modem_send_s        : std_logic;
  signal pipe_data_counter_s : std_logic_vector(7 downto 0);

  -- RX FIFO signals
  signal rx_fifo_os_data_s     : std_logic_vector(7 downto 0);
  signal rx_fifo_os_dv_s       : std_logic;
  signal rx_fifo_os_rfd_s      : std_logic;
  signal rx_fifo_empty_s       : std_logic;
  signal rx_fifo_full_s        : std_logic;
  signal rx_fifo_data_count_s  : std_logic_vector(7 downto 0);
  -- TX FIFO signals
  signal tx_fifo_os_data_s     : std_logic_vector(7 downto 0);
  signal tx_fifo_os_dv_s       : std_logic;
  signal tx_fifo_os_rfd_s      : std_logic;
  signal tx_fifo_empty_s       : std_logic;
  signal tx_fifo_full_s        : std_logic;
  signal tx_fifo_data_count_s  : std_logic_vector(7 downto 0);

  -- Modem signals
  signal modem_is_data_s    : std_logic_vector(7 downto 0);
  signal modem_is_dv_s      : std_logic;
  signal modem_is_rfd_s     : std_logic;
  signal modem_os_data_s    : std_logic_vector(7 downto 0);
  signal modem_os_dv_s      : std_logic;
  signal modem_os_rfd_s     : std_logic;
  -- Modem State
  signal modem_tx_rdy_s     : std_logic;
  signal modem_rx_ovf_s     : std_logic;

--   -- Modulator to channel output
--   signal mod_os_data_s  : std_logic_vector( 9 downto 0);
--   signal mod_os_dv_s    : std_logic;
--   signal mod_os_rfd_s   : std_logic;
--   -- Channel output
--   signal chan_os_data_s : std_logic_vector( 9 downto 0);
--   signal chan_os_dv_s   : std_logic;
--   signal chan_os_rfd_s  : std_logic;

  ---- Modem config
  --constant nm1_bytes_c  : std_logic_vector( 7 downto 0) := X"03";
  --constant nm1_pre_c    : std_logic_vector( 7 downto 0) := X"07";
  --constant nm1_sfd_c    : std_logic_vector( 7 downto 0) := X"03";
  --constant det_th_c     : std_logic_vector(15 downto 0) := X"0040";
  --constant pll_kp_c     : std_logic_vector(15 downto 0) := X"A000";
  --constant pll_ki_c     : std_logic_vector(15 downto 0) := X"9000";
  ---- Channel config
  --constant sigma_c      : std_logic_vector(15 downto 0) := X"0040"; -- QU16.12
  ---- Modem config
  --signal nm1_bytes_s  : std_logic_vector( 7 downto 0);
  --signal nm1_pre_s    : std_logic_vector( 7 downto 0);
  --signal nm1_sfd_s    : std_logic_vector( 7 downto 0);
  --signal det_th_s     : std_logic_vector(15 downto 0);
  --signal pll_kp_s     : std_logic_vector(15 downto 0);
  --signal pll_ki_s     : std_logic_vector(15 downto 0);
  ---- Channel config
  --signal sigma_s      : std_logic_vector(15 downto 0);
  ------------------------------------------------------------------------------
  
  -- ------------------------------------------------------------------------------
  -- -- VIO SIGNALS
  -- ------------------------------------------------------------------------------
  -- COMPONENT vio_0
  --   PORT (
  --   clk : IN STD_LOGIC;
  --   probe_out0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
  --   probe_out1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
  --   probe_out2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
  --   probe_out3 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
  --   probe_out4 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
  --   probe_out5 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
  --   probe_out6 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  --   );
  -- END COMPONENT;
  -- ------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  ---- DEBUG SIGNALS
  --------------------------------------------------------------------------------
  ---- ILA
  --signal tx_s : std_logic;
  ---- ILA component
  --COMPONENT ila_0
  --PORT (
  --    clk : IN STD_LOGIC;
  --    probe0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
  --    probe1 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
  --    probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  --    probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
  --);
  --END COMPONENT  ;
  --------------------------------------------------------------------------------

begin


  ------------------------------------------------------------------------------
  -- Generate synchronous reset
  ------------------------------------------------------------------------------
  arst_n_s <= not(arst_i);
  u_srst : process(clk_i)
  begin
    if rising_edge(clk_i) then
      srst_s <= arst_i;
    end if;
  end process;
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- UART
  ------------------------------------------------------------------------------
  -- UART Module
  u_uart : sif_uart
    generic map (
      CLK_FREQ  => MODEM_CLK_FREQ, --frequency of system clock in Hertz
      BAUD_RATE => UART_BAUD_RATE, --data link baud rate in bits/second
      OS_RATE   => 16,             --oversampling rate to find center of receive bits (in samples per baud period)
      D_WIDTH   => 8,              --data bus width
      PARITY    => 0,              --0 for no parity, 1 for parity
      PARITY_EO => '0'             --'0' for even, '1' for odd parity
    )
    port map (
      -- clk, srst
      clk_i        => clk_i,
      srst_i       => srst_s,
      -- Serial Interface
      rx_i         => rx_i,
      tx_o         => tx_o,
      -- Input Stream Interface
      tx_is_data_i => rx_fifo_os_data_s,
      tx_is_dv_i   => rx_fifo_os_dv_s,
      tx_is_rfd_o  => rx_fifo_os_rfd_s,
      -- Output Stream Interface
      rx_os_data_o => uart_os_data_s,
      rx_os_dv_o   => uart_os_dv_s,
      rx_os_rfd_i  => uart_os_rfd_s,
      -- Status
      rx_err_o     => uart_rx_err_s,
      rx_ovf_o     => uart_rx_ovf_s
    );
  ---------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- TX FIFO
  ------------------------------------------------------------------------------
  u_tx_fifo : sif_fifo
  generic map (
    MEM_SIZE     => 256
  )
  port map (
    -- clk, srst
    clk_i        => clk_i,
    srst_i       => srst_s,
    -- Input Stream Interface
    is_data_i    => uart_os_data_s,
    is_dv_i      => uart_os_dv_s,
    is_rfd_o     => uart_os_rfd_s,
    -- Output Stream Interface
    os_data_o    => tx_fifo_os_data_s,
    os_dv_o      => tx_fifo_os_dv_s,
    os_rfd_i     => tx_fifo_os_rfd_s,
    -- Status
    empty_o      => tx_fifo_empty_s,
    full_o       => tx_fifo_full_s,
    data_count_o => tx_fifo_data_count_s
  );
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- SEND CONTROL: send_s signal logic
  ------------------------------------------------------------------------------
  u_send_logic : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_s = '1' then
        pipe_data_counter_s <= (others => '0');
        modem_send_s <= '0';
        -- modem_tx_rdy_d10_s <= (others => '0');
      else
        if  uart_os_dv_s   = '1' and
            uart_os_rfd_s  = '1' and
            modem_is_dv_s  = '1' and
            modem_is_rfd_s = '1'
        then
          pipe_data_counter_s <= pipe_data_counter_s;
        elsif  modem_is_dv_s  = '1' and
               modem_is_rfd_s = '1'
        then
          pipe_data_counter_s <= std_logic_vector(unsigned(pipe_data_counter_s)-1);
        elsif  uart_os_dv_s   = '1' and
               uart_os_rfd_s  = '1'
        then
          pipe_data_counter_s <= std_logic_vector(unsigned(pipe_data_counter_s)+1);
        end if;
        if modem_send_s = '1' then
          modem_send_s <= '0';
        else
          if unsigned(pipe_data_counter_s) > unsigned(nm1_bytes_i) and modem_tx_rdy_s = '1' then
            modem_send_s <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Modem
  ------------------------------------------------------------------------------
  -- I want to keep the modem_is_... signals, in case new blocks are added
  -- between the tx_fifo and the modem.
  modem_is_data_s    <= tx_fifo_os_data_s;
  modem_is_dv_s      <= tx_fifo_os_dv_s;
  tx_fifo_os_rfd_s   <= modem_is_rfd_s;
  -- Modem module
  u_modem : bb_modem
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => '1',
    srst_i        => srst_s,
    -- Input Stream
    is_data_i     => modem_is_data_s,
    is_dv_i       => modem_is_dv_s,
    is_rfd_o      => modem_is_rfd_s,
    -- Output Stream
    os_data_o     => modem_os_data_s,
    os_dv_o       => modem_os_dv_s,
    os_rfd_i      => modem_os_rfd_s,
    -- DAC Stream
    dac_os_data_o => mod_os_data_o,
    dac_os_dv_o   => mod_os_dv_o,
    dac_os_rfd_i  => mod_os_rfd_i,
    -- ADC Stream
    adc_is_data_i => chan_os_data_i,
    adc_is_dv_i   => chan_os_dv_i,
    adc_is_rfd_o  => chan_os_rfd_o,
    -- Config
    nm1_bytes_i   => nm1_bytes_i,
    nm1_pre_i     => nm1_pre_i,
    nm1_sfd_i     => nm1_sfd_i,
    det_th_i      => det_th_i,
    pll_kp_i      => pll_kp_i,
    pll_ki_i      => pll_ki_i,
    -- Control
    send_i        => modem_send_s,
    -- State
    tx_rdy_o      => modem_tx_rdy_s,
    rx_ovf_o      => modem_rx_ovf_s
  );
  ------------------------------------------------------------------------------


  ------------------------------------------------------------------------------
  -- RX FIFO
  ------------------------------------------------------------------------------
  u_rx_fifo : sif_fifo
  generic map (
    MEM_SIZE     => 256
  )
  port map (
    -- clk, srst
    clk_i        => clk_i,
    srst_i       => srst_s,
    -- Input Stream Interface
    is_data_i    => modem_os_data_s,
    is_dv_i      => modem_os_dv_s,
    is_rfd_o     => modem_os_rfd_s,
    -- Output Stream Interface
    os_data_o    => rx_fifo_os_data_s,
    os_dv_o      => rx_fifo_os_dv_s,
    os_rfd_i     => rx_fifo_os_rfd_s,
    -- Status
    empty_o      => rx_fifo_empty_s,
    full_o       => rx_fifo_full_s,
    data_count_o => rx_fifo_data_count_s
  );
  ------------------------------------------------------------------------------

end architecture;
