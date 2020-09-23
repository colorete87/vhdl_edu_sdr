-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity zero_append is
  generic
  (
    N_ZEROS       : integer;
    CLOG2_N_ZEROS : integer
  );
  port
  (
    -- clk, en, rst
    clk_i         : in  std_logic;
    en_i          : in  std_logic;
    srst_i        : in  std_logic;
    -- Input Stream
    is_mdata_i    : in  std_logic_vector(1 downto 0);
    is_dv_i       : in  std_logic;
    is_rfd_o      : out std_logic;
    -- Output Stream
    os_deltas_o   : out std_logic_vector(1 downto 0);
    os_dv_o       : out std_logic;
    os_rfd_i      : in  std_logic
  );
end entity zero_append;

-- architecture
architecture rtl of zero_append is

  signal internal_enable_s   : std_logic;
  signal input_reg_enable_s  : std_logic;
  signal counter_s           : std_logic_vector(CLOG2_N_ZEROS-1 downto 0);
  signal counter_last_s      : std_logic;

begin

  is_rfd_o <= en_i and os_rfd_i and counter_last_s;
  internal_enable_s <= en_i and is_dv_i and os_rfd_i;
  input_reg_enable_s <= internal_enable_s and counter_last_s;

  u_counter : process (clk_i)
    variable counter_v : integer;
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        -- counter_v and counter_last_s
        counter_v := N_ZEROS;
        counter_last_s <= '1';
      else
        if internal_enable_s = '1' then
          -- counter_v and counter_last_s
          counter_v := counter_v + 1;
          if counter_v > N_ZEROS then
            counter_v := 0;
            counter_last_s <= '1';
          else
            counter_last_s <= '0';
          end if;
        end if;
      end if;
      counter_s <= std_logic_vector(to_unsigned(counter_v,CLOG2_N_ZEROS));
    end if;
  end process;

  u_out_reg : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        os_deltas_o <= (others => '0');
        os_dv_o <= '0';
      else
        if internal_enable_s = '1' then
          if counter_s = std_logic_vector(to_unsigned(N_ZEROS,CLOG2_N_ZEROS)) then
            os_deltas_o <= is_mdata_i;
          else
            os_deltas_o <= (others => '0');
          end if;
          os_dv_o <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture rtl;


