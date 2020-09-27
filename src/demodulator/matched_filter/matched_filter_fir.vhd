-- libraries
library ieee;
use ieee.std_logic_1164.all;


-- entity
entity matched_filter_fir is
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
end entity matched_filter_fir;

-- architecture
architecture rtl of matched_filter_fir is

  component hdlcoder_matched_filter_fir is
    port(
      clk          :   in    std_logic; 
      clk_enable   :   in    std_logic; 
      reset        :   in    std_logic; 
      filter_in    :   in    std_logic_vector(9 DOWNTO 0); -- sfix2
      filter_out   :   out   std_logic_vector(9 DOWNTO 0)  -- sfix10_En9
    );
  end component hdlcoder_matched_filter_fir;

  signal internal_enable_s : std_logic;
  signal os_dv_sr_s : std_logic_vector(1 downto 0);

begin

  is_rfd_o <= en_i and os_rfd_i;
  internal_enable_s <= en_i and os_rfd_i and is_dv_i;

  process(clk_i)
  begin
    if rising_edge(clk_I) then
      if srst_i = '1' then
        os_dv_sr_s <= (others => '0');
      else
        if internal_enable_s = '1' then
          os_dv_sr_s(0) <= is_dv_i;
          os_dv_sr_s(1) <= os_dv_sr_s(0);
        end if;
      end if;
    end if; 
  end process;
  os_dv_o <= os_dv_sr_s(1);


  u_fir : hdlcoder_matched_filter_fir
  port map
  (
    clk          => clk_i,
    clk_enable   => internal_enable_s,
    reset        => srst_i,
    filter_in    => is_data_i,
    filter_out   => os_data_o
  );

end architecture rtl;




