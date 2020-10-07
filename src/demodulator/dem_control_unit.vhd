library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dem_control_unit is
  -- generic(
  --   N_PULSE : integer
  -- );
  port(
    -- clk, en, rst
    clk_i           : in  std_logic;
    en_i            : in  std_logic;
    srst_i          : in  std_logic;
    -- Config
    nm1_bytes_i     : in  std_logic_vector(7 downto 0);
    nm1_pre_i       : in  std_logic_vector(7 downto 0);
    nm1_sfd_i       : in  std_logic_vector(7 downto 0);
    -- send_i          : in  std_logic;
    -- map_is_rfd_i    : in  std_logic;
    -- Output signals
    -- data_symb_sel_o : out std_logic_vector(2 downto 0);
    -- out_symb_sel_o  : out std_logic_vector(1 downto 0);
    -- zero_out_o      : out std_logic;
    -- bbm_is_rfd_o    : out std_logic;
    -- input_reg_en_o  : out std_logic;
    -- Input
    bit_i           : in  std_logic;
    new_bit_i       : in  std_logic;
    signal_det_i    : in  std_logic;
    -- Output
    bit_counter_o   : out std_logic_vector(10 downto 0);
    data_det_o      : out std_logic
  );
end entity;

architecture rtl of dem_control_unit is

  -- Build an enumerated type for the state machine
  type state_type is (S_INIT, S_WAIT, S_PRE_S0, S_PRE_S1, S_SFD_S0, S_SFD_S1, S_DATA);
  
  -- Register to hold the current state
  signal state_s      : state_type;
  signal next_state_s : state_type;

  -- Signals
  -- signal send_d1_s              : std_logic;
  -- signal start_tx_s             : std_logic;
  -- signal counter_s              : std_logic_vector(7+3 downto 0);
  -- signal counter_srst_s         : std_logic;
  -- signal base_symb_idx_s        : std_logic;
  -- signal internal_enable_s      : std_logic;
  -- signal bbm_is_rfd_s           : std_logic;

  signal bit_counter_s      : unsigned(10 downto 0);
  signal bit_counter_srst_s : std_logic;

begin

  -- Output
  data_det_o    <= '1' when state_s = S_DATA else '0';
  bit_counter_o <= std_logic_vector(bit_counter_s);

  -- Bit Counter
  bit_counter_srst_s <= '1' when srst_i = '1' else
                        '1' when state_s = S_PRE_S0 and next_state_s = S_SFD_S0 and new_bit_i = '1' else
                        '1' when state_s = S_PRE_S1 and next_state_s = S_SFD_S0 and new_bit_i = '1' else
                        '1' when state_s = S_SFD_S0 and next_state_s = S_DATA   and new_bit_i = '1' else
                        '1' when state_s = S_SFD_S1 and next_state_s = S_DATA   and new_bit_i = '1' else
                        '1' when state_s = S_DATA   and next_state_s = S_WAIT   and new_bit_i = '1' else
                        '0';
  u_bit_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if bit_counter_srst_s = '1' then
        bit_counter_s <= (others => '0');
      else
        if en_i = '1' and new_bit_i = '1' and signal_det_i = '1' then
          bit_counter_s <= bit_counter_s + 1;
        end if;
      end if;
    end if;
  end process;

  -- State Register
  process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if srst_i = '1' then
        state_s <= S_INIT;
      else
        if en_i = '1' and new_bit_i = '1' then
          state_s <= next_state_s;
        end if;
      end if;
    end if;
  end process;

  -- Next State Combinational Logic
  process (state_s,signal_det_i,bit_counter_s,bit_i,nm1_sfd_i,nm1_pre_i,nm1_bytes_i)
  begin
    case state_s is
      when S_INIT   =>
        next_state_s <= S_WAIT;
      when S_WAIT   =>
        if signal_det_i = '1' and bit_i = '0' then
          next_state_s <= S_PRE_S0;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_PRE_S0 =>
        if signal_det_i = '1' then
          if bit_i = '1' then
            next_state_s <= S_PRE_S1;
          else
            if bit_counter_s(7 downto 0) >= unsigned(nm1_sfd_i) then
              next_state_s <= S_SFD_S0;
            else
              next_state_s <= S_PRE_S0;
            end if;
          end if;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_PRE_S1 =>
        if signal_det_i = '1' then
          if bit_i = '0' then
            next_state_s <= S_PRE_S0;
          else
            if bit_counter_s(7 downto 0) >= unsigned(nm1_sfd_i) then
              next_state_s <= S_SFD_S0;
            else
              next_state_s <= S_WAIT;
            end if;
          end if;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_SFD_S0 =>
        if signal_det_i = '1' then
          if bit_counter_s(7 downto 0) = unsigned(nm1_sfd_i)  then
            next_state_s <= S_DATA;
          else
            if bit_i = (nm1_pre_i(0) xor nm1_sfd_i(0))  then
              next_state_s <= S_SFD_S1;
            else
              if bit_i = '0' then
                next_state_s <= S_PRE_S0;
              else
                next_state_s <= S_WAIT;
              end if;
            end if;
          end if;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_SFD_S1 =>
        if signal_det_i = '1' then
          if bit_counter_s(7 downto 0) = unsigned(nm1_sfd_i)  then
            next_state_s <= S_DATA;
          else
            if bit_i = not(nm1_pre_i(0) xor nm1_sfd_i(0))  then
              next_state_s <= S_SFD_S0;
            else
              if bit_i = '0' then
                next_state_s <= S_PRE_S0;
              else
                next_state_s <= S_WAIT;
              end if;
            end if;
          end if;
        else
          next_state_s <= S_WAIT;
        end if;
      when S_DATA   =>
        if bit_counter_s = unsigned(nm1_bytes_i)&"111" then
          next_state_s <= S_WAIT;
        else
          next_state_s <= S_DATA;
        end if;
    end case;
  end process;
  
  -- -- Output Logic (Combinational Logic)
  -- -- which is only function of the state
  -- tx_rdy_o <= '1' when state_s = S_WAIT else '0';
  -- zero_out_o <= '0' when state_s = S_DATA or
  --                        state_s = S_PRE  or
  --                        state_s = S_SFD  else '1';

  -- process (state_s,en_i,counter_s,counter_srst_s,map_is_rfd_i,internal_enable_s,nm1_sfd_i)
  -- begin
  --   bbm_is_rfd_s   <= '0';
  --   case state_s is
  --     when S_INIT =>
  --     when S_WAIT =>
  --     when S_PRE =>
  --     when S_SFD =>
  --       if counter_s(7 downto 0) = nm1_sfd_i then
  --         bbm_is_rfd_s <=  en_i and map_is_rfd_i and internal_enable_s;
  --       end if;
  --     when S_DATA =>
  --       if counter_s(2 downto 0) = "111" then
  --         bbm_is_rfd_s <= en_i and map_is_rfd_i and internal_enable_s;
  --       end if;
  --   end case;
  -- end process;

  -- -- Muxes selection
  -- data_symb_sel_o <= counter_s(2 downto 0);
  -- out_symb_sel_o <= '0' & base_symb_idx_s      when state_s = S_PRE else
  --                   '0' & not(base_symb_idx_s) when state_s = S_SFD else
  --                   "10"                       when state_s = S_DATA else
  --                   "00";
  
end rtl;
