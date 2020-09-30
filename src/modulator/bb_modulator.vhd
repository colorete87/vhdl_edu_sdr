-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity bb_modulator is
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
    -- Config, control and state
    nm1_bytes_i   : in  std_logic_vector(7 downto 0);
    nm1_pre_i     : in  std_logic_vector(7 downto 0);
    nm1_sfd_i     : in  std_logic_vector(7 downto 0);
    send_i        : in  std_logic;
    tx_rdy_o      : out std_logic
  );
end entity bb_modulator;

-- architecture
architecture rtl of bb_modulator is

  component mod_control_unit is
    generic(
      N_PULSE : integer
     );
    port(
      -- clk, en, rst
      clk_i            : in  std_logic;
      en_i             : in  std_logic;
      srst_i           : in  std_logic;
      -- Input signals
      nm1_bytes_i      : in  std_logic_vector(7 downto 0);
      nm1_pre_i        : in  std_logic_vector(7 downto 0);
      nm1_sfd_i        : in  std_logic_vector(7 downto 0);
      send_i           : in  std_logic;
      is_dv_i          : in  std_logic;
      map_is_rfd_i     : in  std_logic;
      -- Output signals
      data_symb_sel_o  : out std_logic_vector(2 downto 0);
      out_symb_sel_o   : out std_logic_vector(1 downto 0);
      zero_out_o       : out std_logic;
      bbm_is_rfd_o     : out std_logic;
      input_reg_en_o   : out std_logic;
      tx_rdy_o         : out std_logic
    );
  end component;

  component bask_mapper is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_zero_out_i : in  std_logic;
      is_symb_i     : in  std_logic;
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_mdata_o    : out std_logic_vector(1 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component bask_mapper;

  component zero_append is
    generic
    (
      N_ZEROS       : integer;
      CLOG2_N_ZEROS : integer
    );
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_mdata_i    : in  std_logic_vector(1 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_deltas_o   : out std_logic_vector(1 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component zero_append;

  component pulse_shaping_fir is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(1 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(9 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component pulse_shaping_fir;

  -- constants
  constant N_PULSE : integer := 16;

  -- signals

  -- Packer signals
  signal input_reg_s     : std_logic_vector(7 downto 0);
  signal input_reg_en_s  : std_logic;
  signal data_symb_s     : std_logic;
  signal data_symb_sel_s : std_logic_vector(2 downto 0);
  signal out_symb_s      : std_logic;
  signal out_symb_sel_s  : std_logic_vector(1 downto 0);
  signal zero_out_s      : std_logic;
  signal map_is_dv_s     : std_logic;
  signal map_is_rfd_s    : std_logic;

  -- Mapper Output Stream Signals
  signal map_os_data_s   : std_logic_vector(1 downto 0);
  signal map_os_dv_s     : std_logic;
  signal map_os_rfd_s    : std_logic;

  -- Zero Append Output Stream Signals
  signal za_os_data_s   : std_logic_vector(1 downto 0);
  signal za_os_dv_s     : std_logic;
  signal za_os_rfd_s    : std_logic;

  -- signal za_srst_s      : std_logic; -- TODO for desynchronization of different TXs 

begin

  -- Input Register
  u_r0 : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        input_reg_s <= (others => '0');
      else
        if input_reg_en_s = '1' then
          input_reg_s <= is_data_i;
        end if;
      end if;
    end if;
  end process;

  -- Data Symbol Mux
  u_data_symbol_mux :
  data_symb_s <= input_reg_s(to_integer(unsigned(data_symb_sel_s)));

  -- Out Symbol Mux
  u_out_symbol_mux :
  out_symb_s <= '0'         when out_symb_sel_s = "00" else 
                '1'         when out_symb_sel_s = "01" else 
                data_symb_s when out_symb_sel_s = "10" else 
                '0';

  -- Control Unit
  u_cu : mod_control_unit
  generic map (
    N_PULSE => N_PULSE
  )
  port map (
    -- clk, en, rst
    clk_i           => clk_i,
    en_i            => en_i,
    srst_i          => srst_i,
    -- Input signals
    nm1_bytes_i     => nm1_bytes_i,
    nm1_pre_i       => nm1_pre_i,
    nm1_sfd_i       => nm1_sfd_i,
    send_i          => send_i,
    is_dv_i         => is_dv_i,
    map_is_rfd_i    => map_is_rfd_s,
    -- Output signals
    data_symb_sel_o => data_symb_sel_s,
    out_symb_sel_o  => out_symb_sel_s,
    zero_out_o      => zero_out_s,
    bbm_is_rfd_o    => is_rfd_o,
    input_reg_en_o  => input_reg_en_s,
    tx_rdy_o        => tx_rdy_o
  );

  -- Mapper
  map_is_dv_s <= '1';
  u_mapper : bask_mapper
  port map (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_zero_out_i => zero_out_s,
    is_symb_i     => out_symb_s,
    is_dv_i       => map_is_dv_s,
    is_rfd_o      => map_is_rfd_s,
    -- Output Stream
    os_mdata_o    => map_os_data_s,
    os_dv_o       => map_os_dv_s,
    os_rfd_i      => map_os_rfd_s
  );

  -- Zero Append
  u_zero_append : zero_append
  generic map
  (
    N_ZEROS       => N_PULSE-1,
    CLOG2_N_ZEROS => 4
  )
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_mdata_i    => map_os_data_s,
    is_dv_i       => map_os_dv_s,
    is_rfd_o      => map_os_rfd_s,
    -- Output Stream
    os_deltas_o   => za_os_data_s,
    os_dv_o       => za_os_dv_s,
    os_rfd_i      => za_os_rfd_s
  );

  -- Pulse-Shaping FIR
  u_fir : pulse_shaping_fir
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => za_os_data_s, 
    is_dv_i       => za_os_dv_s,
    is_rfd_o      => za_os_rfd_s,
    -- Output Stream
    os_data_o     => os_data_o,
    os_dv_o       => os_dv_o,
    os_rfd_i      => os_rfd_i
  );

end architecture rtl;

