-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_edu_bbt.all;

-- entity
entity top_edu_bbt is
  port(
    clk_i   : in  std_logic;                    --system clock
    arst_i  : in  std_logic;                    --ascynchronous reset
    rx_i    : in  std_logic;                    --receive pin
    tx_o    : out std_logic
  );
end entity top_edu_bbt;

-- architecture
architecture rtl of top_edu_bbt is


  -- UART signals
  signal arst_n_s     : std_logic;
  signal srst_s       : std_logic := '1';
  signal tx_data_s    : std_logic_vector(7 downto 0);
  signal tx_busy_s    : std_logic;
  signal tx_en_s      : std_logic;
  signal rx_data_s    : std_logic_vector(7 downto 0);
  signal rx_busy_s    : std_logic;
  signal rx_busy_d1_s : std_logic;

  -- UART IF signals
  signal uart_os_data_s     : std_logic_vector(7 downto 0);
  signal uart_os_dv_s       : std_logic;
  signal uart_os_rfd_s      : std_logic;
  signal uart_is_data_s     : std_logic_vector(7 downto 0);
  signal uart_is_dv_s       : std_logic;
  signal uart_is_rfd_s      : std_logic;
  signal uart_rx_ovf_o      : std_logic;
  signal uart_new_rx_data_s : std_logic;

  -- FIFO signals
  signal fifo_data_s        : std_logic_vector(7 downto 0);
  signal fifo_re_s          : std_logic;
  signal fifo_re2_s         : std_logic;
  signal fifo_empty_s       : std_logic;
  signal fifo_full_s        : std_logic;
  signal fifo_data_count_s  : std_logic_vector(7 downto 0);
  signal fifo_os_data_s     : std_logic_vector(7 downto 0);
  signal fifo_os_dv_s       : std_logic;
  signal fifo_os_rfd_s      : std_logic;

  -- Modem signals
  signal modem_os_data_s    : std_logic_vector(7 downto 0);
  signal modem_os_dv_s      : std_logic;
  signal modem_os_rfd_s     : std_logic;
  -- Modem Control
  signal modem_send_s       : std_logic;
  -- Modem State
  signal modem_tx_rdy_s     : std_logic;
  signal modem_rx_ovf_s     : std_logic;
  -- signal modem_tx_rdy_d10_s : std_logic_vector(9 downto 0);

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

    COMPONENT ila_0
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT  ;

  signal tx_s : std_logic_vector(0 downto 0);

begin

    u_ila0 : ila_0
    PORT MAP (
        clk => clk_i,
        probe0 => mod_os_data_s,
        probe1 => chan_os_data_s,
        probe2 => tx_data_s,
        probe3 => tx_s
    );
    tx_o <= tx_s(0);


  -- Generate synchronous reset
  arst_n_s <= not(arst_i);
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
    reset_n   => arst_n_s,   --ascynchronous reset
    tx_ena    => tx_en_s,    --initiate transmission
    tx_data   => tx_data_s,  --data to transmit
    rx        => rx_i,       --receive pin
    rx_busy   => rx_busy_s,  --data reception in progress
    rx_error  => open,       --start, parity, or stop bit error detected
    rx_data   => rx_data_s,  --data received
    tx_busy   => tx_busy_s,  --transmission in progress
    tx        => tx_s(0)     --transmit pin
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
  tx_data_s     <= modem_os_data_s;
  tx_en_s       <= modem_os_dv_s and not(tx_busy_s);
  uart_is_rfd_s <= not(tx_busy_s);

  -- FIFO
  u_rx_fifo : simple_fifo
  generic map (
    MEM_SIZE     => 256
  )
  port map (
    Clock        => clk_i,
    Reset        => srst_s,
    We           => uart_os_dv_s,
    Wr_data      => uart_os_data_s,
    Re           => fifo_re_s,
    Rd_data      => fifo_data_s,
    Empty        => fifo_empty_s,
    Full         => fifo_full_s,
    data_count_o => fifo_data_count_s
  );
  fifo_os_data_s <= fifo_data_s;
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_re_s      <= fifo_os_rfd_s and fifo_os_dv_s;
  -- fifo_re_s <= uart_is_rfd_s when fifo_data_count_s > X"03" and uart_is_rfd_s = '1' else '0';
  uart_os_rfd_s <= not(fifo_full_s);
  u_fifo_os : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_s = '1' then
        fifo_os_dv_s   <= '0';
        -- fifo_re2_s      <= '0';
      else
        -- if fifo_empty_s = '0' and fifo_os_dv_s = '0' then
        --   fifo_re2_s      <= '1';
        -- elsif fifo_empty_s = '0' and fifo_os_dv_s = '1' and fifo_os_rfd_s = '1' then
        --   fifo_re2_s      <= '1';
        -- else
        --   fifo_re2_s      <= '0';
        -- end if;
        if fifo_re_s = '1' then
          if fifo_empty_s = '0' then
            fifo_os_dv_s <= '1'; 
          else
            fifo_os_dv_s <= '0'; 
          end if;
        else
          if fifo_os_dv_s = '1' and fifo_os_rfd_s = '1' then
            fifo_os_dv_s <= '0'; 
          end if;
        end if;
        -- if fifo_os_rfd_s = '1' then
        --   if fifo_empty_s = '1' then
        --     fifo_os_dv_s   <= '0';
        --   else
        --     fifo_os_dv_s   <= '1';
        --   end if;
        -- end if;
      end if;
    end if;
  end process;
  -- fifo_re_s <= fifo_re2_s and not(fifo_empty_s);
  fifo_re_s <= (not(fifo_empty_s) and not(fifo_os_dv_s))
               or
               (not(fifo_empty_s) and fifo_os_dv_s and fifo_os_rfd_s);

  -- send_s signal logic
  u_send_logic : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_s = '1' then
        modem_send_s <= '0';
        -- modem_tx_rdy_d10_s <= (others => '0');
      else
        -- modem_tx_rdy_d10_s <= modem_tx_rdy_d10_s(8 downto 0) & modem_tx_rdy_s;
        if modem_send_s = '1' then
          modem_send_s <= '0';
        else
          -- if unsigned(fifo_data_count_s) >= unsigned(nm1_bytes_c) and modem_tx_rdy_d10_s(9) = '1' then
          if unsigned(fifo_data_count_s) >= unsigned(nm1_bytes_c) and modem_tx_rdy_s = '1' then
            modem_send_s <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Modem
  u_modem : bb_modem
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => '1',
    srst_i        => srst_s,
    -- Input Stream
    is_data_i     => fifo_os_data_s,
    is_dv_i       => fifo_os_dv_s,
    is_rfd_o      => fifo_os_rfd_s,
    -- Output Stream
    os_data_o     => modem_os_data_s,
    os_dv_o       => modem_os_dv_s,
    os_rfd_i      => modem_os_rfd_s,
    -- DAC Stream
    dac_os_data_o => mod_os_data_s,
    dac_os_dv_o   => mod_os_dv_s,
    dac_os_rfd_i  => mod_os_rfd_s,
    -- ADC Stream
    adc_is_data_i => chan_os_data_s,
    adc_is_dv_i   => chan_os_dv_s,
    adc_is_rfd_o  => chan_os_rfd_s,
    -- Config
    nm1_bytes_i   => nm1_bytes_c,  
    nm1_pre_i     => nm1_pre_c,    
    nm1_sfd_i     => nm1_sfd_c,    
    det_th_i      => det_th_c,
    pll_kp_i      => pll_kp_c,
    pll_ki_i      => pll_ki_c,
    -- Control    
    send_i        => modem_send_s,
    -- State      
    tx_rdy_o      => modem_tx_rdy_s,
    rx_ovf_o      => modem_rx_ovf_s
  );

  -- UART is
  uart_is_data_s  <= modem_os_data_s;
  uart_is_dv_s    <= modem_os_dv_s;
  modem_os_rfd_s  <= uart_is_rfd_s;

  -- Channel
  u_channel : bb_channel
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => '1',
    srst_i        => srst_s,
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

end architecture;
