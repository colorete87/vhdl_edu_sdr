-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity
entity bb_demodulator is
  port
  (
    -- clk, en, rst
    clk_i         : in  std_logic;
    en_i          : in  std_logic;
    srst_i        : in  std_logic;
    -- Input Stream
    is_data_i     : in  std_logic_vector( 9 downto 0);
    is_dv_i       : in  std_logic;
    is_rfd_o      : out std_logic;
    -- Output Stream
    os_data_o     : out std_logic_vector( 7 downto 0);
    os_dv_o       : out std_logic;
    os_rfd_i      : in  std_logic;
    -- Config, control and state
    nm1_bytes_i   : in  std_logic_vector( 7 downto 0);
    nm1_pre_i     : in  std_logic_vector( 7 downto 0);
    nm1_sfd_i     : in  std_logic_vector( 7 downto 0);
    det_th_i      : in  std_logic_vector(15 downto 0);
    pll_kp_i      : in  std_logic_vector(15 downto 0);
    pll_ki_i      : in  std_logic_vector(15 downto 0);
    rx_rdy_o      : out std_logic
  );
end entity bb_demodulator;

-- architecture
architecture rtl of bb_demodulator is

  component matched_filter_fir is
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
  end component matched_filter_fir;

  component shift_reg is
    generic (
      sr_depth : integer;
      sr_width : integer
    );
    port (
      clk    : in  std_logic;
      rst    : in  std_logic; -- Optional
      sr_in  : in  std_logic_vector(sr_width - 1 downto 0);
      sr_out : out std_logic_vector(sr_width - 1 downto 0)
    );
  end component;

  component symb_sync is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector( 9 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output
      en_sample_o   : out std_logic;
      -- State
      locked_o      : out std_logic
    );
  end component symb_sync;

  -- constants
  constant N_PULSE   : integer := 16;
  constant MAX_N_SFD : integer := 8;

  -- signals
  -- Modulator output
  signal mf_data_s     : std_logic_vector( 9 downto 0);
  signal mf_dv_s       : std_logic;
  signal mf_rfd_s      : std_logic;
  signal mfd_data_s    : std_logic_vector( 9 downto 0);

  signal en_sample_s   : std_logic;
  signal samples_s     : std_logic_vector( 9 downto 0);
  signal bit_s         : std_logic;
  signal last_bits_s   : std_logic_vector(MAX_N_SFD-1 downto 0);
  signal bit_counter_s : std_logic_vector( 9 downto 0);


begin

  mf_rfd_s <= '1'; --TODO: REMOVE

  u_matched_filter : matched_filter_fir
  port map(
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => is_data_i,
    is_dv_i       => is_dv_i,
    is_rfd_o      => is_rfd_o,
    -- Output Stream
    os_data_o     => mf_data_s,
    os_dv_o       => mf_dv_s,
    os_rfd_i      => mf_rfd_s
  );

  u_shift_reg : shift_reg
  generic map (
    sr_depth => 13,
    sr_width => 10
  )
  port map (
    clk    => clk_i,
    rst    => srst_i,
    sr_in  => mf_data_s,
    sr_out => mfd_data_s
  );

  u_symb_sync : symb_sync
  port map
  (
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => mf_data_s,        
    is_dv_i       => mf_dv_s,         
    is_rfd_o      => mf_rfd_s,       
    -- Output
    en_sample_o   => en_sample_s,
    -- State
    locked_o      => open
  );

  u_sampler : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        samples_s   <= (others => '0');
        bit_s       <= '0';
        last_bits_s <= (others => '0');
      else
        if en_sample_s = '1' then
          samples_s   <= mfd_data_s;
          bit_s       <= mfd_data_s(9);
          last_bits_s <= mfd_data_s(9) & last_bits_s(last_bits_s'high downto 1);
        end if;
      end if;
    end if;
  end process;

  u_bit_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        bit_counter_s <= (others => '0');
      else
        if en_sample_s = '1' then
          -- bit_counter_s <= mfd_data_s(9);
        end if;
      end if;
    end if;
  end process;

end architecture rtl;

