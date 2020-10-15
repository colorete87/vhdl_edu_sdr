--------------------------------------------------------------------------------
-- TODO
--------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity sif_fifo is
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
end entity sif_fifo;
    
architecture rtl of sif_fifo is

  component simple_fifo is
    generic (
      RESET_ACTIVE_LEVEL : std_logic := '1';
      MEM_SIZE           : positive;
      SYNC_READ          : boolean    := true
      );
    port (
      Clock   : in std_logic;
      Reset   : in std_logic;
      We      : in std_logic;  --# Write enable
      Wr_data : in std_logic_vector;

      Re      : in  std_logic;
      Rd_data : out std_logic_vector;

      Empty : out std_logic;
      Full  : out std_logic;
      data_count_o : out std_logic_vector(integer(ceil(log2(real(MEM_SIZE))))-1 downto 0)
      );
  end component;

  -- -- UART signals
  -- signal arst_n_s     : std_logic;
  -- signal srst_s       : std_logic := '1';
  -- signal tx_data_s    : std_logic_vector(7 downto 0);
  -- signal tx_busy_s    : std_logic;
  -- signal tx_en_s      : std_logic;
  -- signal rx_data_s    : std_logic_vector(7 downto 0);
  -- signal rx_busy_s    : std_logic;
  -- signal rx_busy_d1_s : std_logic;

  -- -- UART IF signals
  -- signal uart_os_data_s     : std_logic_vector(7 downto 0);
  -- signal uart_os_dv_s       : std_logic;
  -- signal uart_os_rfd_s      : std_logic;
  -- signal uart_rx_ovf_o      : std_logic;
  -- signal uart_new_rx_data_s : std_logic;

  -- -- Modem Control
  -- signal modem_send_s        : std_logic;
  -- signal pipe_data_counter_s : std_logic_vector(7 downto 0);

  -- -- FIFO signals
  signal fifo_re_s          : std_logic;
  -- signal fifo_re2_s         : std_logic;
  signal fifo_empty_s       : std_logic;
  signal fifo_full_s        : std_logic;
  signal fifo_data_count_s  : std_logic_vector(7 downto 0);
  -- signal fifo_os_data_s     : std_logic_vector(7 downto 0);
  signal os_dv_s       : std_logic;
  -- signal fifo_os_rfd_s      : std_logic;

  -- -- Modem signals
  -- signal modem_os_data_s    : std_logic_vector(7 downto 0);
  -- signal modem_os_dv_s      : std_logic;
  -- signal modem_os_rfd_s     : std_logic;
  -- -- Modem State
  -- signal modem_tx_rdy_s     : std_logic;
  -- signal modem_rx_ovf_s     : std_logic;
  -- -- signal modem_tx_rdy_d10_s : std_logic_vector(9 downto 0);

  -- -- Modulator to channel output
  -- signal mod_os_data_s  : std_logic_vector( 9 downto 0);
  -- signal mod_os_dv_s    : std_logic;
  -- signal mod_os_rfd_s   : std_logic;
  -- -- Channel output
  -- signal chan_os_data_s : std_logic_vector( 9 downto 0);
  -- signal chan_os_dv_s   : std_logic;
  -- signal chan_os_rfd_s  : std_logic;

  -- -- Modem config
  -- constant nm1_bytes_c  : std_logic_vector( 7 downto 0) := X"03";
  -- constant nm1_pre_c    : std_logic_vector( 7 downto 0) := X"07";
  -- constant nm1_sfd_c    : std_logic_vector( 7 downto 0) := X"03";
  -- constant det_th_c     : std_logic_vector(15 downto 0) := X"0040";
  -- constant pll_kp_c     : std_logic_vector(15 downto 0) := X"A000";
  -- constant pll_ki_c     : std_logic_vector(15 downto 0) := X"9000";
  -- -- Channel config
  -- constant sigma_c      : std_logic_vector(15 downto 0) := X"0040"; -- QU16.12

  -- -- ILA
  -- signal tx_s : std_logic;
  -- -- ILA component
  -- COMPONENT ila_0
  -- PORT (
  --     clk : IN STD_LOGIC;
  --     probe0 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
  --     probe1 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
  --     probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  --     probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
  -- );
  -- END COMPONENT  ;

begin


  -- Status
  full_o <= fifo_full_s;
  empty_o <= fifo_empty_s;


  -- ---------------------------------------------------------------------------
  -- FIFO
  -- ---------------------------------------------------------------------------
  u_rx_fifo : simple_fifo
  generic map (
    MEM_SIZE     => 256
  )
  port map (
    Clock        => clk_i,
    Reset        => srst_i,
    We           => is_dv_i,
    Wr_data      => is_data_i,
    Re           => fifo_re_s,
    Rd_data      => os_data_o,
    Empty        => fifo_empty_s,
    Full         => fifo_full_s,
    data_count_o => fifo_data_count_s
  );
  data_count_o <= fifo_data_count_s;
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_os_dv_s   <= '1' when fifo_data_count_s > X"00" else '0';
  -- fifo_re_s      <= fifo_os_rfd_s and fifo_os_dv_s;
  -- fifo_re_s <= uart_is_rfd_s when fifo_data_count_s > X"03" and uart_is_rfd_s = '1' else '0';
  is_rfd_o <= not(fifo_full_s);
  os_dv_o <= os_dv_s;
  u_fifo_os : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        os_dv_s   <= '0';
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
            os_dv_s <= '1'; 
          else
            os_dv_s <= '0'; 
          end if;
        else
          if os_dv_s = '1' and os_rfd_i = '1' then
            os_dv_s <= '0'; 
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
  fifo_re_s <= (not(fifo_empty_s) and not(os_dv_s))
               or
               (not(fifo_empty_s) and os_dv_s and os_rfd_i);
  -- ---------------------------------------------------------------------------

end architecture;
