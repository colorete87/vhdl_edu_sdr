-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_edu_bbt.all;

Library UNISIM;
use UNISIM.vcomponents.all;

-- entity
entity hw_top_uart_loopback is
  port(
    clk_i   : in  std_logic;                    --system clock
    arst_i  : in  std_logic;                    --ascynchronous reset
    rx_i    : in  std_logic;                    --receive pin
    tx_o    : out std_logic;
    led_o   : out std_logic_vector(3 downto 0)
  );
end entity hw_top_uart_loopback;

-- architecture
architecture rtl of hw_top_uart_loopback is
 
  COMPONENT ila_0
  PORT (
    clk : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
  END COMPONENT;

  component clk_wiz_0
  port (
    -- Clock in ports
    -- Clock out ports
    clk_out1          : out    std_logic; -- 16 MHz
    -- Status and control signals
    reset             : in     std_logic;
    locked            : out    std_logic;
    clk_in1           : in     std_logic  -- 125 MHz
   );
  end component;

  signal clk_s        : std_logic;
  signal clk_locked_s : std_logic;

  signal rx_s : std_logic_vector(0 downto 0);
  signal tx_s : std_logic_vector(0 downto 0);

  signal counter_s : std_logic_vector(26 downto 0);

begin

  u_blinky : process(clk_s,arst_i)
  begin
    if arst_i = '1' then
      counter_s <= (others => '0');
    elsif rising_edge(clk_s) then
      counter_s <= std_logic_vector(unsigned(counter_s)+1);
    end if;
  end process;
  led_o <= counter_s(26 downto 23);

  u_clk_mmcm : clk_wiz_0
  port map (
    -- Clock out ports
    clk_out1 => clk_s,
    -- Status and control signals
    reset    => arst_i,
    locked   => clk_locked_s,
    -- Clock in ports
    clk_in1  => clk_i
  );
  -- clk_s <= clk_i;

  u_top : top_uart_loopback
  port map
  (
    clk_i  => clk_s,
    arst_i => arst_i,
    rx_i   => rx_s(0),
    tx_o   => tx_s(0)
  );
  -- tx_s <= rx_s;

  rx_s(0) <= rx_i;
  tx_o    <= tx_s(0);

  u_ila0 : ila_0
  port map (
    clk    => clk_s,
    probe0 => rx_s,
    probe1 => tx_s
  );

end architecture;

