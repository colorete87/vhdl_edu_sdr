-- libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- entity
entity symb_sync is
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
    -- Config
    pll_kp_i      : in  std_logic_vector(15 downto 0);
    pll_ki_i      : in  std_logic_vector(15 downto 0);
    -- Output
    en_sample_o   : out std_logic;
    -- State
    locked_o      : out std_logic
  );
end entity symb_sync;

-- architecture
architecture rtl of symb_sync is

  component pre_filter is
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
  end component pre_filter;

  component bandpass_filter is
    port
    (
      -- clk, en, rst
      clk_i         : in  std_logic;
      en_i          : in  std_logic;
      srst_i        : in  std_logic;
      -- Input Stream
      is_data_i     : in  std_logic_vector(12 downto 0);
      is_dv_i       : in  std_logic;
      is_rfd_o      : out std_logic;
      -- Output Stream
      os_data_o     : out std_logic_vector(19 downto 0);
      os_dv_o       : out std_logic;
      os_rfd_i      : in  std_logic
    );
  end component bandpass_filter;

  component pll is
    generic
    (
      WORD_WIDTH        : integer   := 16
    );
    port
    (
      -- clk, en, rst
      clk_i           : in  std_logic;
      en_i            : in  std_logic;
      srst_i          : in  std_logic;
      -- Input Stream
      is_data_i       : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      -- is_dv_i         : in  std_logic;
      -- is_rfd_o        : out std_logic;
      -- Output Stream
      os_sin_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
      os_cos_o        : out std_logic_vector(WORD_WIDTH-1 downto 0);
      -- os_dv_o         : out std_logic;
      -- os_rfd_i        : in  std_logic;
      -- Config       
      freq_zqero_i    : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      pll_kp_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      pll_ki_i        : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      -- State        
      phase_err_o     : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      phase_int_err_o : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      phase_o         : in  std_logic_vector(WORD_WIDTH-1 downto 0)
    );
  end component pll;


  -- constants

  -- signals
  signal internal_enbale_s    : std_logic;
  signal pf_s                 : std_logic_vector( 9 downto 0);
  signal pf_sq_s              : std_logic_vector(12 downto 0);
  signal pf_sq_bpf_s          : std_logic_vector(19 downto 0);
  signal pll_input_s          : std_logic_vector(15 downto 0);
  signal pll_os_sin_s         : std_logic_vector(15 downto 0);
  signal pll_os_cos_s         : std_logic_vector(15 downto 0);
  signal pll_phase_err_s      : std_logic_vector(15 downto 0);
  signal pll_phase_int_err_s  : std_logic_vector(15 downto 0);
  signal pll_phase_s          : std_logic_vector(15 downto 0);
  signal clk_i_s              : std_logic;
  signal clk_q_s              : std_logic;
  signal clk_i_1d_s           : std_logic;
  signal clk_q_1d_s           : std_logic;

begin

  internal_enbale_s <= en_i and is_dv_i;

  is_rfd_o <= '1';

  -- Pre-filter
  u_pre_filter : pre_filter
  port map(
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => is_data_i,
    is_dv_i       => '1',
    is_rfd_o      => open,
    -- Output Stream
    os_data_o     => pf_s,
    os_dv_o       => open,
    os_rfd_i      => '1'
  );
  -- Uncomment following lines to eliminate pre-filter (and comment previous)
  -- u_pre : process(clk_i)
  -- begin
  --   if rising_edge(clk_i) then
  --     if srst_i = '1' then
  --       pf_s <= (others => '0');
  --     else
  --       if internal_enbale_s = '1' then
  --         pf_s <= is_data_i;
  --       end if;
  --     end if;
  --   end if;
  -- end process;

  -- Square law
  u_sq : process(clk_i)
    variable aux_v : unsigned(19 downto 0);
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        pf_sq_s <= (others => '0');
      else
        if internal_enbale_s = '1' then
          aux_v := unsigned(signed(pf_s) * signed(pf_s));
          pf_sq_s <= std_logic_vector(aux_v(12 downto 0)); -- TODO a ojo
        end if;
      end if;
    end if;
  end process;

  -- BP-filter
  u_bandpass_filter : bandpass_filter
  port map(
    -- clk, en, rst
    clk_i         => clk_i,
    en_i          => en_i,
    srst_i        => srst_i,
    -- Input Stream
    is_data_i     => pf_sq_s,
    is_dv_i       => '1',
    is_rfd_o      => open,
    -- Output Stream
    os_data_o     => pf_sq_bpf_s,
    os_dv_o       => open,
    os_rfd_i      => '1'
  );
  -- Uncomment following lines to eliminate bandpass-filter (and comment previous)
  -- u_bpf : process(clk_i)
  -- begin
  --   if rising_edge(clk_i) then
  --     if srst_i = '1' then
  --       pf_sq_bpf_s <= (others => '0');
  --     else
  --       if internal_enbale_s = '1' then
  --         pf_sq_bpf_s <= pf_sq_s;
  --       end if;
  --     end if;
  --   end if;
  -- end process;

  -- PLL
  pll_input_s <= pf_sq_bpf_s(17 downto 2); -- TODO: Hardcoded
  u_pll : pll
  generic map
  (
    WORD_WIDTH        => 16
  )
  port map
  (
    -- clk, en, rst
    clk_i           => clk_i,
    en_i            => internal_enbale_s,
    srst_i          => srst_i,
    -- Input Stream
    is_data_i       => pll_input_s,
    -- Output Stream
    os_sin_o        => pll_os_sin_s,
    os_cos_o        => pll_os_cos_s,
    -- Config       
    freq_zqero_i    => std_logic_vector(to_unsigned(4096,16)), -- f_0 = 2^bits/(number of clocks per pulse)
    pll_kp_i        => pll_kp_i,
    pll_ki_i        => pll_ki_i,
    -- State        
    phase_err_o     => pll_phase_err_s,
    phase_int_err_o => pll_phase_int_err_s,
    phase_o         => pll_phase_s
  );

  -- clks
  clk_i_s <= pll_os_cos_s(pll_os_cos_s'high);
  clk_q_s <= pll_os_sin_s(pll_os_sin_s'high);
  u_clk_d : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if srst_i = '1' then
        clk_i_1d_s <= '0';
        clk_q_1d_s <= '0';
      else
        if internal_enbale_s = '1' then
          clk_i_1d_s <= clk_i_s;
          clk_q_1d_s <= clk_q_s;
        end if;
      end if;
    end if;
  end process;

  -- Output
  en_sample_o <= clk_i_s and not(clk_i_1d_s);

end architecture rtl;


