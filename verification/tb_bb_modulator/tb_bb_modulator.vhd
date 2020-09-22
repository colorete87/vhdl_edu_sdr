-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity
entity tb_bb_modulator is
end entity tb_bb_modulator;

-- architecture
architecture rtl of tb_bb_modulator is

  -- components
  component bb_modulator is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(7 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic;
      -- Control and report IOs
      send_i        : in  std_logic;
      tx_rdy_o      : out std_logic
    );
  end component bb_modulator;

  -- signals
  signal tb_dut_clk_i      : std_logic;                   
  signal tb_dut_en_i       : std_logic;                    
  signal tb_dut_srst_i     : std_logic;                   
  signal tb_dut_is_data_i  : std_logic_vector(7 downto 0);                            
  signal tb_dut_is_dv_i    : std_logic;
  signal tb_dut_is_rfd_o   : std_logic;
  signal tb_dut_os_data_o  : std_logic_vector(9 downto 0);                            
  signal tb_dut_os_dv_o    : std_logic;
  signal tb_dut_os_rfd_i   : std_logic;
  signal tb_dut_send_i     : std_logic;
  signal tb_dut_tx_rdy_o   : std_logic;
                             
begin

  dut : bb_modulator
  port map (
    -- clk, en, rst
    clk_i         => tb_dut_clk_i,
    en_i          => tb_dut_en_i,
    srst_i        => tb_dut_srst_i,
    -- Input Stream
    is_data_i     => tb_dut_is_data_i,
    is_dv_i       => tb_dut_is_dv_i,
    is_rfd_o      => tb_dut_is_rfd_o,
    -- Output Stream
    os_data_o     => tb_dut_os_data_o,
    os_dv_o       => tb_dut_os_dv_o,
    os_rfd_i      => tb_dut_os_rfd_i,
    -- Control and report IOs
    send_i        => tb_dut_send_i,
    tx_rdy_o      => tb_dut_tx_rdy_o
  );

  tb_dut_clk_i <= not tb_dut_clk_i after 5 ns;


  process
    variable byte_v : integer := 0;
  begin
    tb_dut_en_i       <= '1';
    tb_dut_srst_i     <= '1';
    tb_dut_is_data_i  <= std_logic_vector(to_unsigned(byte_v,8));
    tb_dut_is_dv_i    <= '0';
    tb_dut_os_rfd_i   <= '1';
    wait until rising_edge(tb_dut_clk_i);
    wait until rising_edge(tb_dut_clk_i);
    wait for 3000 ns;
    wait;
  end process;

  process
    variable byte_v : integer := 0;
  begin
    tb_dut_send_i     <= '0';
    for i in 1 to 10 loop
      for j in 1 to 100 loop
        wait until rising_edge(tb_dut_clk_i);
      end loop;
      tb_dut_send_i     <= '1';
      wait until rising_edge(tb_dut_clk_i);
      wait until rising_edge(tb_dut_clk_i);
      tb_dut_send_i     <= '0';
    end loop;
  end process;

end architecture;



