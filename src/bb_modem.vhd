-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity bb_modem is
  port
  (
    -- clk, en, rst
    clk_i            : in  std_logic;
    en_i             : in  std_logic;
    srst_i           : in  std_logic;
    -- Input Stream
    is_data_i        : in  std_logic_vector( 7 downto 0);
    is_dv_i          : in  std_logic;
    is_rfd_o         : out std_logic;
    -- Output Stream
    os_data_o        : out std_logic_vector( 7 downto 0);
    os_dv_o          : out std_logic;
    os_rfd_i         : in  std_logic;
    -- DAC Stream
    dac_os_data_o    : out std_logic_vector( 9 downto 0);
    dac_os_dv_o      : out std_logic;
    dac_os_rfd_i     : in  std_logic;
    -- ADC Stream
    adc_is_data_i    : in  std_logic_vector( 9 downto 0);
    adc_is_dv_i      : in  std_logic;
    adc_is_rfd_o     : out std_logic;
    -- Config
    nm1_bytes_i      : in  std_logic_vector( 7 downto 0);
    nm1_pre_i        : in  std_logic_vector( 7 downto 0);
    nm1_sfd_i        : in  std_logic_vector( 7 downto 0);
    det_th_i         : in  std_logic_vector(15 downto 0);
    pll_kp_i         : in  std_logic_vector(15 downto 0);
    pll_ki_i         : in  std_logic_vector(15 downto 0);
    -- Control    
    send_i           : in  std_logic;
    -- State      
    tx_rdy_o         : out std_logic;
    rx_ovf_o         : out std_logic
  );
end entity bb_modem;

-- architecture
architecture rtl of bb_modem is

  -- components
  component bb_modulator is
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
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic;
      -- Config, control and state
      nm1_bytes_i   : in  std_logic_vector(7 downto 0);
      nm1_pre_i     : in  std_logic_vector(7 downto 0);
      nm1_sfd_i     : in  std_logic_vector(7 downto 0);
      send_i        : in  std_logic;
      tx_rdy_o      : out std_logic
    );
  end component bb_modulator;

  component bb_demodulator is
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
      os_data_o     : out std_logic_vector( 7 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic;
      -- Config, control and state
      nm1_bytes_i   : in  std_logic_vector( 7 downto 0);
      nm1_pre_i     : in  std_logic_vector( 7 downto 0);
      nm1_sfd_i     : in  std_logic_vector( 7 downto 0);
      det_th_i      : in  std_logic_vector(15 downto 0);
      pll_kp_i      : in  std_logic_vector(15 downto 0);
      pll_ki_i      : in  std_logic_vector(15 downto 0);
      rx_ovf_o      : out std_logic
    );
  end component bb_demodulator;

begin

  -- Modulator
  u_mod : bb_modulator
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
    os_data_o     => dac_os_data_o,
    os_dv_o       => dac_os_dv_o,
    os_rfd_i      => dac_os_rfd_i,
    -- Config, control and state
    nm1_bytes_i   => nm1_bytes_i,
    nm1_pre_i     => nm1_pre_i,
    nm1_sfd_i     => nm1_sfd_i,
    send_i        => send_i,
    tx_rdy_o      => tx_rdy_o
  );

  -- Demodulator
  u_dem : bb_demodulator
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => adc_is_data_i,
    is_dv_i       => adc_is_dv_i,
    is_rfd_o      => adc_is_rfd_o,
    -- Output Stream
    os_data_o     => os_data_o,
    os_dv_o       => os_dv_o,
    os_rfd_i      => os_rfd_i,
    -- Config, control and state
    nm1_bytes_i   => nm1_bytes_i,  
    nm1_pre_i     => nm1_pre_i,    
    nm1_sfd_i     => nm1_sfd_i,    
    det_th_i      => det_th_i,
    pll_kp_i      => pll_kp_i,
    pll_ki_i      => pll_ki_i,
    rx_ovf_o      => rx_ovf_o
  );

end architecture rtl;


