library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity moving_average is
  generic (
    NBIT         : integer := 8;
    DEPTH        : integer := 16
  );
  port (
    clk_i        : in  std_logic;
    srst_i       : in  std_logic;
    en_i         : in  std_logic;
    -- input
    data_i       : in  std_logic_vector(NBIT-1 downto 0);
    -- output
    data_o       : out std_logic_vector(NBIT-1 downto 0);
    data_valid_o : out std_logic
  );
end;


architecture rtl of moving_average is

  type sgn_array_1d_t is array (0 to DEPTH-1) of unsigned(NBIT-1 downto 0);
  constant CLOG2_DEPTH    : integer := integer(ceil(log2(real(DEPTH))));
  signal shift_reg_s      : sgn_array_1d_t;
  signal acc_s            : unsigned(NBIT+CLOG2_DEPTH-1 downto 0);
  signal data_valid_s     : std_logic;
  signal last_data_s      : unsigned(NBIT-1 downto 0);

begin

  p_average : process(clk_i)
  begin
    if srst_i = '1' then
      acc_s         <= (others => '0');
      shift_reg_s   <= (others => (others => '0'));
      data_valid_s  <= '0';
      data_valid_o  <= '0';
      data_o        <= (others => '0');
    elsif rising_edge(clk_i) then
      data_valid_s  <= en_i;
      data_valid_o  <= data_valid_s;
      shift_reg_s   <= unsigned(data_i) & shift_reg_s(0 to shift_reg_s'length-2);
      acc_s         <= acc_s + unsigned(data_i) - last_data_s;
      data_o        <= std_logic_vector(acc_s(NBIT+CLOG2_DEPTH-1 downto CLOG2_DEPTH));
    end if;
  end process p_average;

  last_data_s <= shift_reg_s(shift_reg_s'length-1);

end rtl;
