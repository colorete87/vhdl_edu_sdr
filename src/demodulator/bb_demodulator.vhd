-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity bb_demodulator is
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
    rx_rdy_o      : out std_logic
  );
end entity bb_demodulator;

-- architecture
architecture rtl of bb_demodulator is

  component pulse_shaping_fir is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(1 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component pulse_shaping_fir;

  -- constants
  constant N_PULSE : integer := 16;

  -- signals

begin

  is_rfd_o <= '1';

end architecture rtl;

