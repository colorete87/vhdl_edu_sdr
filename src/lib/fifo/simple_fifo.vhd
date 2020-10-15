library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library work;
use work.pkg_edu_bbt.all;

entity simple_fifo is
  generic (
    RESET_ACTIVE_LEVEL : std_logic := '1';
    MEM_SIZE           : positive;
    SYNC_READ          : boolean    := true
    );
  port (
    Clock   : in std_logic;
    Reset   : in std_logic;
    We      : in std_logic;  --# Write enable
    Wr_data : in std_logic_vector;

    Re      : in  std_logic;
    Rd_data : out std_logic_vector;

    Empty : out std_logic;
    Full  : out std_logic;
    data_count_o : out std_logic_vector(integer(ceil(log2(real(MEM_SIZE))))-1 downto 0)
    );
end entity;

architecture rtl of simple_fifo is

  signal head, tail : natural range 0 to MEM_SIZE-1;
  signal dpr_we     : std_logic;
  signal wraparound : boolean;

  signal empty_loc, full_loc : std_logic;
begin

  dpr : dual_port_ram
    generic map (
      MEM_SIZE  => MEM_SIZE,
      SYNC_READ => SYNC_READ
      )
    port map (
      Wr_clock => Clock,
      We       => dpr_we,
      Wr_addr  => head,
      Wr_data  => Wr_data,

      Rd_clock => Clock,
      Re       => Re,
      Rd_addr  => tail,
      Rd_data  => Rd_data
      );

  dpr_we <= '1' when we = '1' and full_loc = '0' else '0';

  wr_rd : process(Clock) is
    variable head_v, tail_v : natural range 0 to MEM_SIZE-1;
    variable wraparound_v   : boolean;
  begin

    if rising_edge(Clock) then
        if Reset = RESET_ACTIVE_LEVEL then
          head         <= 0;
          tail         <= 0;
          full_loc     <= '0';
          empty_loc    <= '1';
          -- Almost_full  <= '0';
          -- Almost_empty <= '0';
    
          wraparound <= false;
    
        else
          head_v       := head;
          tail_v       := tail;
          wraparound_v := wraparound;
    
          if We = '1' and (wraparound = false or head /= tail) then
            
            if head_v = MEM_SIZE-1 then
              head_v       := 0;
              wraparound_v := true;
            else
              head_v := head_v + 1;
            end if;
          end if;
    
          if Re = '1' and (wraparound = true or head /= tail) then
            if tail_v = MEM_SIZE-1 then
              tail_v       := 0;
              wraparound_v := false;
            else
              tail_v := tail_v + 1;
            end if;
          end if;
    
    
          if head_v /= tail_v then
            empty_loc <= '0';
            full_loc  <= '0';
          else
            if wraparound_v then
              full_loc <= '1';
              empty_loc <= '0';
            else
              full_loc <= '0';
              empty_loc <= '1';
            end if;
          end if;
    
          if head_v >= tail_v then
            data_count_o <= std_logic_vector(to_unsigned(head_v-tail_v,integer(ceil(log2(real(MEM_SIZE))))));
          else
            data_count_o <= std_logic_vector(to_unsigned(head_v+MEM_SIZE-tail_v,integer(ceil(log2(real(MEM_SIZE))))));
          end if;
          -- if not(wraparound_v) then
          --   data_count_o <= std_logic_vector(to_unsigned(head_v - tail_v,integer(ceil(log2(real(MEM_SIZE))))));
          -- else
          --   data_count_o <= std_logic_vector(to_unsigned(head_v + MEM_SIZE-tail_v,integer(ceil(log2(real(MEM_SIZE))))));
          -- end if;
    
          -- Almost_full  <= '0';
          -- Almost_empty <= '0';
          -- if head_v /= tail_v then
          --   if head_v > tail_v then
          --     if Almost_full_thresh >= MEM_SIZE - (head_v - tail_v) then
          --       Almost_full <= '1';
          --     end if;
          --     if Almost_empty_thresh >= head_v - tail_v then
          --       Almost_empty <= '1';
          --     end if;
          --   else
          --     if Almost_full_thresh >= tail_v - head_v then
          --       Almost_full <= '1';
          --     end if;
          --     if Almost_empty_thresh >= MEM_SIZE - (tail_v - head_v) then
          --       Almost_empty <= '1';
          --     end if;
          --   end if;
          -- end if;
    
    
          head       <= head_v;
          tail       <= tail_v;
          wraparound <= wraparound_v;
      end if;
    end if;
  end process;

  Empty <= empty_loc;
  Full  <= full_loc;

end architecture;
