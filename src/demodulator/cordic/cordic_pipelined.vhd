library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity cordic_pipelined is
  generic (
    WW       : positive;
    STAGES : positive;
    RESET_ACTIVE_LEVEL : std_ulogic := '1'
  );
  port (
    Clock : in std_ulogic;
    Reset : in std_ulogic;

    Mode : in std_ulogic;

    X : in signed(WW-1 downto 0);
    Y : in signed(WW-1 downto 0);
    Z : in signed(WW-1 downto 0);

    X_result : out signed(WW-1 downto 0);
    Y_result : out signed(WW-1 downto 0);
    Z_result : out signed(WW-1 downto 0)
  );
end entity;

architecture rtl of cordic_pipelined is
  type signed_pipeline is array (natural range <>) of signed(WW-1 downto 0);

  signal x_pl, y_pl, z_pl : signed_pipeline(1 to STAGES);
  signal x_array, y_array, z_array : signed_pipeline(0 to STAGES);

  function gen_atan_table(N : positive; M : positive) return signed_pipeline is
    variable table : signed_pipeline(0 to M-1);
  begin
    for i in table'range loop
      table(i) := to_signed(integer(arctan(2.0**(-i)) * 2.0**N / MATH_2_PI), N);
    end loop;

    return table;
  end function;

  constant ATAN_TABLE : signed_pipeline(0 to STAGES-1) := gen_atan_table(WW, STAGES);
begin

  x_array <= X & x_pl;
  y_array <= Y & y_pl;
  z_array <= Z & z_pl;

  cordic: process(Clock, Reset) is
    variable negative : boolean;
  begin
    if Reset = RESET_ACTIVE_LEVEL then
      x_pl <= (others => (others => '0'));
      y_pl <= (others => (others => '0'));
      z_pl <= (others => (others => '0'));

    elsif rising_edge(Clock) then
      for i in 1 to STAGES loop
        if Mode = '1' then
          negative := z_array(i-1)(z'high) = '1';
        else
          negative := y_array(i-1)(y'high) = '0';
        end if;

        --if z_array(i-1)(z'high) = '1' then -- z is negative
        if negative then
          x_pl(i) <= x_array(i-1) + (y_array(i-1) / 2**(i-1));
          y_pl(i) <= y_array(i-1) - (x_array(i-1) / 2**(i-1));
          z_pl(i) <= z_array(i-1) + ATAN_TABLE(i-1);
        else -- z or y is positive
          x_pl(i) <= x_array(i-1) - (y_array(i-1) / 2**(i-1));
          y_pl(i) <= y_array(i-1) + (x_array(i-1) / 2**(i-1));
          z_pl(i) <= z_array(i-1) - ATAN_TABLE(i-1);
        end if;
      end loop;
    end if;
  end process;

  X_result <= x_array(x_array'high);
  Y_result <= y_array(y_array'high);
  Z_result <= z_array(z_array'high);

end architecture;
