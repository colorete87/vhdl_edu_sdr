-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity bb_channel is
  port
  (
    -- clk, en, rst
    clk_i         : in  std_logic;
    en_i          : in  std_logic;
    srst_i        : in  std_logic;
    -- Input Stream
    is_data_i     : in  std_logic_vector(9 downto 0);
    is_dv_i       : in  std_logic;
    is_rfd_o      : out std_logic;
    -- Output Stream
    os_data_o     : out std_logic_vector(9 downto 0);
    os_dv_o       : out std_logic;
    os_rfd_i      : in  std_logic;
    -- Control
    sigma_i       : in  std_logic_vector(15 downto 0)
  );
end entity bb_channel;

-- architecture
architecture rtl of bb_channel is

  -- Components
  component random_gaussian_approx is
    port(
      clk    : in  std_logic;
      reset  : in  std_logic;
      random : out std_logic_vector(11 downto 0)
    );
  end component random_gaussian_approx;

  component bb_channel_fir is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(9 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component bb_channel_fir;

  -- Signals
  signal mid_data_s        : std_logic_vector (9 downto 0);
  -- signal mid_dv_s          : std_logic; -- TODO: REMOVE
  -- signal mid_rfd_s         : std_logic; -- TODO: REMOVE
  signal random_s          : std_logic_vector(11 downto 0);
  signal mult_s            : std_logic_vector(27 downto 0);
  signal noise_s           : std_logic_vector(15 downto 0);
  signal adder_s           : std_logic_vector(15 downto 0);

begin

  u_fir : bb_channel_fir
  port map (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => is_data_i,
    is_dv_i       => '1',
    is_rfd_o      => open,
    -- Output Stream
    os_data_o     => mid_data_s,
    os_dv_o       => open,
    os_rfd_i      => '1'
  );

  -- Noise
  u_noise : random_gaussian_approx
  port map(
    clk    => clk_i,
    reset  => srst_i,
    random => random_s
  );
  -- mult_s <= std_logic_vector(signed(random_s) * signed(sigma_i));
  u_mult_s : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        mult_s <= (others => '0');
      else
        mult_s <= std_logic_vector(signed(random_s) * signed(sigma_i));
      end if;
    end if;
  end process;
  noise_s <= mult_s(27 downto 12);

  -- Adder and Multiplier
  u_mult : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        adder_s <= (others => '0');
      else
        adder_s <= std_logic_vector(resize(signed(mid_data_s),16) + signed(noise_s));
      end if;
    end if;
  end process;

  -- Input
  is_rfd_o  <= '1';
  -- Output
  os_data_o <= adder_s(9 downto 0);
  os_dv_o   <= '1';

end architecture rtl;


