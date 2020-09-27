-- -------------------------------------------------------------
--
-- Module: hdlcoder_pre_filter
-- Generated by MATLAB(R) 8.1 and the Filter Design HDL Coder 2.9.3.
-- Generated on: 2020-09-27 05:22:10
-- -------------------------------------------------------------

-- -------------------------------------------------------------
-- HDL Code Generation Options:
--
-- TargetLanguage: VHDL
-- Name: hdlcoder_pre_filter
-- TestBenchName: hdlcoder_pre_filter_tb

-- -------------------------------------------------------------
-- HDL Implementation    : Fully parallel
-- Multipliers           : 4
-- Folding Factor        : 1
-- -------------------------------------------------------------
-- Filter Settings:
--
-- Discrete-Time IIR Filter (real)
-- -------------------------------
-- Filter Structure    : Direct-Form I, Second-Order Sections
-- Number of Sections  : 1
-- Stable              : Yes
-- Linear Phase        : No
-- Arithmetic          : fixed
-- Numerator           : s16,20 -> [-3.125000e-02 3.125000e-02)
-- Denominator         : s16,14 -> [-2 2)
-- Scale Values        : s16,15 -> [-1 1)
-- Input               : s10,8 -> [-2 2)
-- Output              : s10,5 -> [-16 16)
-- Numerator State     : s16,15 -> [-1 1)
-- Denominator State   : s16,15 -> [-1 1)
-- Numerator Prod      : s32,35 -> [-6.250000e-02 6.250000e-02)
-- Denominator Prod    : s32,29 -> [-4 4)
-- Numerator Accum     : s40,35 -> [-16 16)
-- Denominator Accum   : s40,29 -> [-1024 1024)
-- Round Mode          : convergent
-- Overflow Mode       : wrap
-- Cast Before Sum     : true
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.ALL;

ENTITY hdlcoder_pre_filter IS
   PORT( clk                             :   IN    std_logic; 
         clk_enable                      :   IN    std_logic; 
         reset                           :   IN    std_logic; 
         filter_in                       :   IN    std_logic_vector(9 DOWNTO 0); -- sfix10_En8
         filter_out                      :   OUT   std_logic_vector(9 DOWNTO 0)  -- sfix10_En5
         );

END hdlcoder_pre_filter;


----------------------------------------------------------------
--Module Architecture: hdlcoder_pre_filter
----------------------------------------------------------------
ARCHITECTURE rtl OF hdlcoder_pre_filter IS
  -- Local Functions
  -- Type Definitions
  TYPE numdelay_pipeline_type IS ARRAY (NATURAL range <>) OF signed(15 DOWNTO 0); -- sfix16_En15
  TYPE dendelay_pipeline_type IS ARRAY (NATURAL range <>) OF signed(15 DOWNTO 0); -- sfix16_En15
  -- Constants
  CONSTANT coeff_b1_section1              : signed(15 DOWNTO 0) := to_signed(20195, 16); -- sfix16_En20
  CONSTANT coeff_b2_section1              : signed(15 DOWNTO 0) := to_signed(0, 16); -- sfix16_En20
  CONSTANT coeff_b3_section1              : signed(15 DOWNTO 0) := to_signed(-20195, 16); -- sfix16_En20
  CONSTANT coeff_a2_section1              : signed(15 DOWNTO 0) := to_signed(-31525, 16); -- sfix16_En14
  CONSTANT coeff_a3_section1              : signed(15 DOWNTO 0) := to_signed(15753, 16); -- sfix16_En14
  -- Signals
  SIGNAL input_register                   : signed(9 DOWNTO 0); -- sfix10_En8
  -- Section 1 Signals 
  SIGNAL numtypeconvert1                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL a1sum1                           : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL dentypeconvert1                  : signed(15 DOWNTO 0); -- sfix16_En15
  SIGNAL numdelay_section1                : numdelay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL dendelay_section1                : dendelay_pipeline_type(0 TO 1); -- sfix16_En15
  SIGNAL a2mul1                           : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL a3mul1                           : signed(31 DOWNTO 0); -- sfix32_En29
  SIGNAL b1mul1                           : signed(31 DOWNTO 0); -- sfix32_En35
  SIGNAL b3mul1                           : signed(31 DOWNTO 0); -- sfix32_En35
  SIGNAL b1sum1                           : signed(39 DOWNTO 0); -- sfix40_En35
  SIGNAL b2sum1                           : signed(39 DOWNTO 0); -- sfix40_En35
  SIGNAL b1multypeconvert1                : signed(39 DOWNTO 0); -- sfix40_En35
  SIGNAL add_cast                         : signed(39 DOWNTO 0); -- sfix40_En35
  SIGNAL add_cast_1                       : signed(39 DOWNTO 0); -- sfix40_En35
  SIGNAL add_temp                         : signed(40 DOWNTO 0); -- sfix41_En35
  SIGNAL midtypeconvert1                  : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL a2sum1                           : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast                         : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_1                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp                         : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL sub_cast_2                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_cast_3                       : signed(39 DOWNTO 0); -- sfix40_En29
  SIGNAL sub_temp_1                       : signed(40 DOWNTO 0); -- sfix41_En29
  SIGNAL output_typeconvert               : signed(9 DOWNTO 0); -- sfix10_En5
  SIGNAL output_register                  : signed(9 DOWNTO 0); -- sfix10_En5


BEGIN

  -- Block Statements
  input_reg_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      input_register <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        input_register <= signed(filter_in);
      END IF;
    END IF; 
  END PROCESS input_reg_process;

  -- ------------------ Section 1 ------------------

  numtypeconvert1 <= resize(input_register(8 DOWNTO 0) & '0' & '0' & '0' & '0' & '0' & '0' & '0', 16);

  dentypeconvert1 <= resize(shift_right(a1sum1(29 DOWNTO 0) + ( "0" & (a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14) & NOT a1sum1(14))), 14), 16);

  numdelay_process_section1 : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      numdelay_section1 <= (OTHERS => (OTHERS => '0'));
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        numdelay_section1(1) <= numdelay_section1(0);
        numdelay_section1(0) <= numtypeconvert1;
      END IF;
    END IF;
  END PROCESS numdelay_process_section1;

  dendelay_process_section1 : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      dendelay_section1 <= (OTHERS => (OTHERS => '0'));
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        dendelay_section1(1) <= dendelay_section1(0);
        dendelay_section1(0) <= dentypeconvert1;
      END IF;
    END IF;
  END PROCESS dendelay_process_section1;

  a2mul1 <= dendelay_section1(0) * coeff_a2_section1;

  a3mul1 <= dendelay_section1(1) * coeff_a3_section1;

  b1mul1 <= numtypeconvert1 * coeff_b1_section1;

  b3mul1 <= numdelay_section1(1) * coeff_b3_section1;

  b1multypeconvert1 <= resize(b1mul1, 40);

  b1sum1 <= b1multypeconvert1;

  add_cast <= b1sum1;
  add_cast_1 <= resize(b3mul1, 40);
  add_temp <= resize(add_cast, 41) + resize(add_cast_1, 41);
  b2sum1 <= add_temp(39 DOWNTO 0);

  midtypeconvert1 <= resize(shift_right(b2sum1(39) & b2sum1(39 DOWNTO 0) + ( "0" & (b2sum1(6) & NOT b2sum1(6) & NOT b2sum1(6) & NOT b2sum1(6) & NOT b2sum1(6) & NOT b2sum1(6))), 6), 40);

  sub_cast <= midtypeconvert1;
  sub_cast_1 <= resize(a2mul1, 40);
  sub_temp <= resize(sub_cast, 41) - resize(sub_cast_1, 41);
  a2sum1 <= sub_temp(39 DOWNTO 0);

  sub_cast_2 <= a2sum1;
  sub_cast_3 <= resize(a3mul1, 40);
  sub_temp_1 <= resize(sub_cast_2, 41) - resize(sub_cast_3, 41);
  a1sum1 <= sub_temp_1(39 DOWNTO 0);

  output_typeconvert <= resize(shift_right(dentypeconvert1(15) & dentypeconvert1(15 DOWNTO 0) + ( "0" & (dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10) & NOT dentypeconvert1(10))), 10), 10);

  Output_Register_process : PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      output_register <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF clk_enable = '1' THEN
        output_register <= output_typeconvert;
      END IF;
    END IF; 
  END PROCESS Output_Register_process;

  -- Assignment Statements
  filter_out <= std_logic_vector(output_register);
END rtl;
