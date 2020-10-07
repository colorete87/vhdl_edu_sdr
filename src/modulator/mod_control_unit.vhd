library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_control_unit is
  generic(
    N_PULSE : integer
   );
  port(
    -- clk, en, rst
    clk_i           : in  std_logic;
    en_i            : in  std_logic;
    srst_i          : in  std_logic;
    -- Input signals
    nm1_bytes_i     : in  std_logic_vector(7 downto 0);
    nm1_pre_i       : in  std_logic_vector(7 downto 0);
    nm1_sfd_i       : in  std_logic_vector(7 downto 0);
    send_i          : in  std_logic;
    is_dv_i         : in  std_logic;
    map_is_rfd_i    : in  std_logic;
    -- Output signals
    data_symb_sel_o : out std_logic_vector(2 downto 0);
    out_symb_sel_o  : out std_logic_vector(1 downto 0);
    zero_out_o      : out std_logic;
    bbm_is_rfd_o    : out std_logic;
    input_reg_en_o  : out std_logic;
    tx_rdy_o        : out std_logic
  );
end entity;

architecture rtl of mod_control_unit is

  -- Build an enumerated type for the state machine
  type state_type is (S_INIT, S_WAIT, S_PRE, S_SFD, S_DATA);
  
  -- Register to hold the current state
  signal state_s      : state_type;
  signal next_state_s : state_type;

  -- Signals
  signal send_d1_s              : std_logic;
  signal start_tx_s             : std_logic;
  signal counter_s              : std_logic_vector(7+3 downto 0);
  signal counter_srst_s         : std_logic;
  signal base_symb_idx_s        : std_logic;
  signal internal_enable_s      : std_logic;
  signal bbm_is_rfd_s           : std_logic;


begin

  -- Input Stream
  bbm_is_rfd_o <= bbm_is_rfd_s;

  -- Flank detector for send_i
  process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        send_d1_s <= '0';
      else
        if en_i = '1' then
          send_d1_s <= send_i;
        end if;
      end if;
    end if;
  end process;

  -- Start
  start_tx_s <= '1' when send_i = '1' and send_d1_s = '0' else
                '0';

  -- Counter reset
  counter_srst_s <= '1' when state_s = S_INIT else
                    '1' when state_s = S_WAIT else
                    '1' when state_s = S_PRE  and counter_s = "000"&nm1_pre_i   and internal_enable_s = '1' else
                    '1' when state_s = S_SFD  and counter_s = "000"&nm1_sfd_i   and internal_enable_s = '1' else
                    '1' when state_s = S_DATA and counter_s = nm1_bytes_i&"111" and internal_enable_s = '1' else
                    '0';

  -- Internal Enable
  u_internal_enable :
  internal_enable_s <= en_i and map_is_rfd_i             when counter_s(7 downto 0) /= nm1_sfd_i else
                       en_i and is_dv_i and map_is_rfd_i;

  -- Input register enable
  u_input_reg_en :
  input_reg_en_o <= bbm_is_rfd_s and is_dv_i;

  -- Base symbol index
  process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        base_symb_idx_s <= '0';
      else
        if internal_enable_s = '1' then
          -- if start_tx_s = '1' then
          --   base_symb_idx_s <= '0';
          -- else
          --   base_symb_idx_s <= not base_symb_idx_s;
          -- end if;
          if
            state_s = S_INIT or
            state_s = S_WAIT or
            state_s = S_DATA
          then
            base_symb_idx_s <= '0';
          else
            base_symb_idx_s <= not base_symb_idx_s;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Counter
  process (clk_i)
    variable counter_v : integer;
    constant MAX       : integer := 255;
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        counter_v := 0;
      elsif counter_srst_s = '1' then
        counter_v := 0;
      else
        if internal_enable_s = '1' then
          counter_v := counter_v + 1;
          if counter_v > MAX then
            counter_v := 0;
          end if;
        end if;
      end if;
      counter_s <= std_logic_vector(to_unsigned(counter_v,11));
    end if;
  end process;

  -- State Register
  process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        state_s <= S_INIT;
      else
        if en_i = '1' then
          state_s <= next_state_s;
        end if;
      end if;
    end if;
  end process;

  -- Next State Combinational Logic
  process (state_s,start_tx_s,counter_srst_s)
  begin
    case state_s is
      when S_INIT =>
        next_state_s <= S_WAIT;
      when S_WAIT =>
        if start_tx_s = '1' then
          next_state_s <= S_PRE;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_PRE =>
        if counter_srst_s = '1' then
          next_state_s <= S_SFD;
        else
          next_state_s <= S_PRE;
        end if;
      when S_SFD =>
        if counter_srst_s = '1' then
          next_state_s <= S_DATA;
        else
          next_state_s <= S_SFD;
        end if;
      when S_DATA =>
        if counter_srst_s = '1' then
          next_state_s <= S_WAIT;
        else
          next_state_s <= S_DATA;
        end if;
    end case;
  end process;
  
  -- Output Logic (Combinational Logic)
  -- which is only function of the state
  tx_rdy_o <= '1' when state_s = S_WAIT else '0';
  zero_out_o <= '0' when state_s = S_DATA or
                         state_s = S_PRE  or
                         state_s = S_SFD  else '1';

  process (state_s,en_i,counter_s,counter_srst_s,map_is_rfd_i,internal_enable_s,nm1_sfd_i)
  begin
    bbm_is_rfd_s   <= '0';
    case state_s is
      when S_INIT =>
      when S_WAIT =>
      when S_PRE =>
      when S_SFD =>
        if counter_s(7 downto 0) = nm1_sfd_i then
          bbm_is_rfd_s <= en_i and map_is_rfd_i and internal_enable_s;
        end if;
      when S_DATA =>
        if counter_s(2 downto 0) = "111" and counter_srst_s = '0' then
          bbm_is_rfd_s <= en_i and map_is_rfd_i and internal_enable_s;
        end if;
    end case;
  end process;

  -- Muxes selection
  data_symb_sel_o <= counter_s(2 downto 0);
  out_symb_sel_o <= '0' & base_symb_idx_s      when state_s = S_PRE else
                    '0' & not(base_symb_idx_s) when state_s = S_SFD else
                    "10"                       when state_s = S_DATA else
                    "00";
  
end rtl;

