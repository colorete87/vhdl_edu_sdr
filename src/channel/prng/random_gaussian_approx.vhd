library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity random_gaussian_approx is
  port(
    clk    : in  std_logic;
    reset  : in  std_logic;
    random : out std_logic_vector(11 downto 0)
  );
end random_gaussian_approx;


architecture Behavioral of random_gaussian_approx is

  component random_uniform is 
  generic(
    SEED      : std_logic_vector(30 downto 0);
    OUT_WIDTH : integer
  );
  port(
    clk    : in  std_logic;
    random : out std_logic_vector (OUT_WIDTH-1 downto 0);
    reset  : in  std_logic
  );
  end component;

  component adder_signed is
    port (
      clk : in  std_logic;
      a   : in  std_logic_vector (11 downto 0);
      b   : in  std_logic_vector (11 downto 0);
      r   : out std_logic_vector (11 downto 0)
    );      
  end component;

  signal uniform1 : std_logic_vector(9 downto 0);
  signal uniform2 : std_logic_vector(9 downto 0);
  signal uniform3 : std_logic_vector(9 downto 0);
  signal uniform4 : std_logic_vector(9 downto 0);

  signal adder_a  : std_logic_vector(11 downto 0);
  signal adder_b  : std_logic_vector(11 downto 0);
  signal adder_r  : std_logic_vector(11 downto 0);

  type statetype is (s0, s1, s2);

  signal state, next_state: statetype := s0;

begin

  unif1: random_uniform 
  generic map (
    SEED => std_logic_vector(to_unsigned(697757461,31)),
    OUT_WIDTH => 10)
  port map(
    clk => clk,
    random => uniform1,
    reset => reset
  );

  unif2: random_uniform 
  generic map (
    SEED => std_logic_vector(to_unsigned(1885540239,31)),
    OUT_WIDTH => 10)
  port map(
      clk => clk,
      random => uniform2,
      reset => reset
  );

  unif3: random_uniform 
  generic map (
    SEED => std_logic_vector(to_unsigned(1505946904,31)),
    OUT_WIDTH => 10)
  port map(
      clk => clk,
      random => uniform3,
      reset => reset
  );

  unif4: random_uniform 
  generic map (SEED => std_logic_vector(to_unsigned(2693445,31)),
                   OUT_WIDTH => 10)
  port map(
      clk => clk,
      random => uniform4,
      reset => reset
  );

  adder1 : adder_signed
    PORT MAP (
      a => adder_a,
      b => adder_b,
      clk => clk,
      r => adder_r
  );

  process(clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= s0;
        random <= (others => '0');
      else
        if state = s0 then
          random <= adder_r;
        end if;
        state <= next_state;
      end if;
    end if;
  end process;


  process(clk,state,uniform1,uniform2,uniform3,uniform4,adder_r)
  begin
    case state is
      when s0 =>
        -- Sign extend
        adder_a <=  uniform1(9)&uniform1(9)&uniform1(9)&uniform1(8 downto 0);
        adder_b <=  uniform2(9)&uniform2(9)&uniform2(9)&uniform2(8 downto 0);
        next_state <= s1;
      when s1 =>
        adder_a <= adder_r;
        adder_b <= uniform3(9)&uniform3(9)&uniform3(9)&uniform3(8 downto 0);
        next_state <= s2;
      when s2 =>
        adder_a <= adder_r;
        adder_b <= uniform4(9)&uniform4(9)&uniform4(9)&uniform4(8 downto 0);
        next_state <= s0;
    end case;
  end process;

end Behavioral;

