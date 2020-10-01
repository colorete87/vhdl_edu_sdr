-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity test_modem_channel is
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
    tx_rdy_o      : out std_logic;
    rx_ovf_o      : out std_logic
  );
end entity test_modem_channel;

-- architecture
architecture rtl of test_modem_channel is

  -- component
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

  -- Modulator output
  signal mod_os_data_s  : std_logic_vector( 9 downto 0);
  signal mod_os_dv_s    : std_logic;
  signal mod_os_rfd_s   : std_logic;
  -- Channel output
  signal chan_os_data_s : std_logic_vector( 9 downto 0);
  signal chan_os_dv_s   : std_logic;
  signal chan_os_rfd_s  : std_logic;

  -- Modem control      : std_logic;
  signal send_s         : std_logic;
  -- Modem State        : std_logic;
  signal tx_rdy_s       : std_logic;
  signal rx_ovf_s       : std_logic;

  -- Modem config
  constant nm1_bytes_c  : std_logic_vector( 7 downto 0) := X"03";
  constant nm1_pre_c    : std_logic_vector( 7 downto 0) := X"07";
  constant nm1_sfd_c    : std_logic_vector( 7 downto 0) := X"03";
  constant det_th_c     : std_logic_vector(15 downto 0) := X"0040";
  constant pll_kp_c     : std_logic_vector(15 downto 0) := X"A000";
  constant pll_ki_c     : std_logic_vector(15 downto 0) := X"9000";
  -- Channel config
  constant sigma_c      : std_logic_vector(15 downto 0) := X"0040"; -- QU16.12

  signal counter_s : integer;

begin

  -- Modem State
  tx_rdy_o <= tx_rdy_s;
  rx_ovf_o <= rx_ovf_s;

  -- Modem Control
  u_modem_control : process(clk_i)
    variable counter_v  : integer;
    variable send_val_v : integer := 123;
    constant VAL_L      : integer := 1242;
    constant VAL_H      : integer := 13;
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        -- counter_v := VAL_L-32;
        counter_v := 0;
        send_s <= '0';
      else
        if en_i = '1' then
          if tx_rdy_s = '1' then
            counter_v := counter_v + 1;
            if counter_v = send_val_v then
              send_s <= '1';
              send_val_v := send_val_v + 67;
              counter_v := 0;
            end if;
          end if;
          if send_s = '1' then
            if counter_v = VAL_H then
              send_s <= '0';
              counter_v := 0;
            else
              counter_v := counter_v + 1;
            end if;
          end if;
          -- counter_v := counter_v + 1;
          -- if send_s = '0' and counter_v = VAL_L then
          --   if tx_rdy_s = '1' then
          --     send_s <= '1';
          --   end if;
          --   counter_v := 0;
          -- end if;
          -- if send_s = '1' and counter_v = VAL_H then
          --   send_s <= '0';
          --   counter_v := 0;
          -- end if;
        end if;
      end if;
      counter_s <= counter_v;
    end if;
  end process;

  -- Modem
  u_modem : bb_modem
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => is_data_i,
    is_dv_i       => is_dv_i,
    is_rfd_o      => is_rfd_o,
    -- Output Stream
    os_data_o     => os_data_o,
    os_dv_o       => os_dv_o,
    os_rfd_i      => os_rfd_i,
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
    send_i        => send_s,
    -- State      
    tx_rdy_o      => tx_rdy_s,
    rx_ovf_o      => rx_ovf_s
  );

  -- Channel
  u_channel : bb_channel
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
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

end architecture rtl;


