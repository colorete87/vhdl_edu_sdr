-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nco is
  generic (
    WW       : positive;       -- Width of parameters
    STAGES : positive; -- Number of CORDIC iterations
    FRAC_BITS  : positive;  -- Total fractional bits
    MAGNITUDE  : real := 1.0;
    RESET_ACTIVE_LEVEL : std_ulogic := '1'
  );
  port (
    Clock : in std_ulogic;
    Reset : in std_ulogic;

    --Load  : in std_ulogic;  -- Start processing a new angle value
    --Done  : out std_ulogic; -- Indicates when iterations are complete

    Angle : in signed(WW-1 downto 0); -- Angle in brads (2**WW brads = 2*pi radians)

    Sin   : out signed(WW-1 downto 0);  -- Sine of Angle
    Cos   : out signed(WW-1 downto 0)   -- Cosine of Angle
  );
end entity;

architecture rtl of nco is

  --## Compute gain from CORDIC pseudo-rotations
  function cordic_gain(n : positive) return real is
    variable g : real := 1.0;
  begin
    for i in 0 to n-1 loop
      g := g * sqrt(1.0 + 2.0**(-2*i));
    end loop;
    return g;
  end function;

  --## Adjust points in the left half of the X-Y plane so that they will
  --#  lie within the +/-99.7 degree convergence zone of CORDIC on the right
  --#  half of the plane. Input vector and angle in x,y,z. Adjusted result
  --#  in xa,ya,za.
  procedure adjust_angle(x, y, z : in signed; signal xa, ya, za : out signed) is
    variable quad : unsigned(1 downto 0);  
    variable zp : signed(z'length-1 downto 0) := z;
    variable yp : signed(y'length-1 downto 0) := y;
    variable xp : signed(x'length-1 downto 0) := x;
  begin
    -- 0-based quadrant number of angle
    quad := unsigned(zp(zp'high downto zp'high-1));
    if quad = 1 or quad = 2 then -- Rotate into quadrant 0 and 3 (right half of plane)
      xp := -xp;
      yp := -yp;
      -- Add 180 degrees (flip the sign bit)
      zp := (not zp(zp'left)) & zp(zp'left-1 downto 0);
    end if;
    xa <= xp;
    ya <= yp;
    za <= zp;
  end procedure;

  component cordic_pipelined is
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
  end component;


  signal xa, ya, za : signed(Angle'range);

begin

  adj: process(Clock, Reset) is
    constant Y : signed(Angle'range) := (others => '0');
    constant X : signed(Angle'range) := --to_signed(1, Angle'length);
      to_signed(integer(MAGNITUDE/cordic_gain(STAGES) * 2.0 ** FRAC_BITS), Angle'length);
  begin

    -- 
    if Reset = RESET_ACTIVE_LEVEL then
      xa <= (others => '0');
      ya <= (others => '0');
      za <= (others => '0');
    elsif rising_edge(Clock) then
      adjust_angle(X, Y, Angle, xa, ya, za);
    end if;
  end process;

  c: cordic_pipelined
    generic map (
      WW => WW,
      STAGES => STAGES,
      RESET_ACTIVE_LEVEL => RESET_ACTIVE_LEVEL
    ) port map (
      Clock => Clock,
      Reset => Reset,

      Mode => '1',

      X => xa,
      Y => ya,
      Z => za,

      X_result => Cos,
      Y_result => Sin,
      Z_result => open
    );

end architecture;

