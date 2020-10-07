library ieee;
use ieee.std_logic_1164.all;

entity dual_port_ram is
  generic (
    MEM_SIZE  : positive;
    SYNC_READ : boolean := true
  );
  port (
    Wr_clock : in std_logic;
    We       : in std_logic; -- Write enable
    Wr_addr  : in natural range 0 to MEM_SIZE-1;
    Wr_data  : in std_logic_vector;

    Rd_clock : in std_logic;
    Re       : in std_logic; -- Read enable
    Rd_addr  : in natural range 0 to MEM_SIZE-1;
    Rd_data  : out std_logic_vector
  );
end entity;

architecture rtl of dual_port_ram is
  type ram_type is array (0 to MEM_SIZE-1) of std_logic_vector(Wr_data'length-1 downto 0);
  signal ram : ram_type;

  signal sync_rdata : std_logic_vector(Rd_data'range);
begin
  assert Wr_data'length = Rd_data'length report "Data bus size mismatch" severity failure;

  wr: process(Wr_clock)
  begin
    if rising_edge(Wr_clock) then
      if We = '1' then
        ram(Wr_addr) <= Wr_data;
      end if;
    end if;
  end process;

  sread: if SYNC_READ = true generate
  rd: process(Rd_clock)
  begin
    if rising_edge(Rd_clock) then
      if Re = '1' then
        sync_rdata <= ram(Rd_addr);
      end if;
    end if;
  end process;
  end generate;

  Rd_data <= ram(Rd_addr) when SYNC_READ = false else sync_rdata;

end architecture;
