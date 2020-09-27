-- libraries
library ieee;
use ieee.std_logic_1164.all;

-- Package Declaration Section
package pkg_edu_bbt is

  component symb_sync is
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
      -- Output
      en_sample_o   : out std_logic;
      -- State
      locked_o      : out std_logic
    );
  end component symb_sync;

end package pkg_edu_bbt;
