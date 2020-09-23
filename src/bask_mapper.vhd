-- libraries
library ieee;
use ieee.std_logic_1164.all;


-- entity
entity bask_mapper is
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
end entity bask_mapper;

-- architecture
architecture rtl of bask_mapper is

  signal internal_enable_s : std_logic;

begin

  is_rfd_o          <= en_i and os_rfd_i;
  internal_enable_s <= en_i and is_dv_i and os_rfd_i;

  u_registers : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        -- os_mdata_o
        os_mdata_o <= "00";
        -- os_dv_o
        os_dv_o <= '0';
      else
        if internal_enable_s = '1' then
          -- os_mdata_o
          if is_zero_out_i = '1' then
            os_mdata_o <= "00";
          else
            if is_symb_i = '1' then 
              os_mdata_o <= "01";
            else
              os_mdata_o <= "11";
            end if;
          end if;
          -- os_dv_o
          os_dv_o <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture rtl;

