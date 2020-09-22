
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_control_unit is
  generic(
    N_PULSE : integer
   );
  port(
    -- clk, en, rst
    clk_i      : in  std_logic;
    en_i       : in  std_logic;
    srst_i     : in  std_logic;
    -- Input signals
    n_bytes_i  : in  std_logic_vector(7 downto 0);
    n_pre_i    : in  std_logic_vector(7 downto 0);
    n_sfd_i    : in  std_logic_vector(7 downto 0);
    send_i     : in  std_logic;
    -- Output signals
    bit_sel_o  : out  std_logic;
    data_sel_o : out  std_logic;
    zero_out_o : out  std_logic;
    tx_rdy_o   : out  std_logic
  );
end entity;

architecture rtl of mod_control_unit is

  -- Build an enumerated type for the state machine
  type state_type is (S_INIT, S_WAIT, S_PRE, S_SFD, S_DATA);
  
  -- Register to hold the current state
  signal state_s      : state_type;
  signal next_state_s : state_type;

  -- Signals
  signal send_d1_s      : std_logic;
  signal start_tx_s     : std_logic;
  signal counter_s      : std_logic_vector(7 downto 0);
  signal counter_srst_s : std_logic;

begin

  -- Flank detector for send_i
  process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if counter_srst_s = '1' then
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
                    '1' when state_s = S_PRE  and counter_s = n_pre_i else
                    '1' when state_s = S_SFD  and counter_s = n_sfd_i else
                    '1' when state_s = S_DATA and counter_s = n_sfd_i else
                    '0';

  -- Counter
  process (clk_i)
    variable counter_v : integer;
  begin
    if (rising_edge(clk_i)) then
      if counter_srst_s = '1' then
        counter_v := 0;
      else
        if en_i = '1' then
          counter_v := counter_v + 1;
          if counter_v >= 256 then
            counter_v := 0;
          end if;
        end if;
      end if;
      counter_s <= std_logic_vector(to_unsigned(counter_v,8));
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

  -- Next State combinational logic
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
      when others =>
        next_state_s <= S_WAIT;
    end case;
  end process;
  
  -- Output depends solely on the current state
  process (state_s)
  begin
    case state_s is
      when S_INIT =>
      when S_WAIT =>
      when S_PRE =>
      when S_SFD =>
      when S_DATA =>
      when others =>
    end case;
  end process;
  
end rtl;
