-- libraries
library ieee;
use ieee.std_logic_1164.all;

entity shift_reg is
  generic (
    sr_depth : integer;
    sr_width : integer
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic; -- Optional
    en     : in  std_logic;
    sr_in  : in  std_logic_vector(sr_width - 1 downto 0);
    sr_out : out std_logic_vector(sr_width - 1 downto 0)
  );
end;

architecture counter_rst of shift_reg is

  type sr_type is array (sr_depth - 2 downto 0)
    of std_logic_vector(sr_width - 1 downto 0);
  signal sr : sr_type;

  signal rst_counter : integer range 0 to sr_depth - 1;

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rst_counter <= 0;
        sr_out <= (others => '0');
      else
        if en = '1' then
          sr <= sr(sr'high - 1 downto sr'low) & sr_in;
          if rst_counter = sr_depth - 1 then
            sr_out <= sr(sr'high);
          else
            rst_counter <= rst_counter + 1;
            sr_out <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture counter_rst;
