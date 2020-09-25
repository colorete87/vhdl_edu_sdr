-- libraries
library ieee;
use ieee.std_logic_1164.all;


-- entity
entity bb_channel is
  port
  (
    -- clk, en, rst
    clk_i         : in  std_logic;
    en_i          : in  std_logic;
    srst_i        : in  std_logic;
    -- Input Stream
    is_zero_out_i : in  std_logic;
    is_symb_i     : in  std_logic;
    is_dv_i       : in  std_logic;
    is_rfd_o      : out std_logic;
    -- Output Stream
    os_mdata_o    : out std_logic_vector(1 downto 0);
    os_dv_o       : out std_logic;
    os_rfd_i      : in  std_logic
  );
end entity bb_channel;

-- architecture
architecture rtl of bb_channel is

  -- Components
  component random_gaussian_approx is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           random : out  STD_LOGIC_VECTOR (11 downto 0));
  end component random_gaussian_approx;

  -- Signals
  signal internal_enable_s : std_logic;

begin

  u_registers : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        os_mdata_o <= "00";
      else
        if internal_enable_s = '1' then
          os_mdata_o <= "00";
        end if;
      end if;
    end if;
  end process;

end architecture rtl;


