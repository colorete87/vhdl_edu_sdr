--------------------------------------------------------------------------------
--
--   FileName:         types.vhd
--   Dependencies:     none
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 8/16/2018 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;

PACKAGE types IS

	CONSTANT taps        : INTEGER := 4; --number of fir filter taps
	CONSTANT data_width  : INTEGER := 4; --width of data input including sign bit
	CONSTANT coeff_width : INTEGER := 4; --width of coefficients including sign bit
	
	TYPE coefficient_array IS ARRAY (0 TO taps-1) OF STD_LOGIC_VECTOR(coeff_width-1 DOWNTO 0);  --array of all coefficients
	TYPE data_array IS ARRAY (0 TO taps-1) OF SIGNED(data_width-1 DOWNTO 0);                    --array of historic data values
	TYPE product_array IS ARRAY (0 TO taps-1) OF SIGNED((data_width + coeff_width)-1 DOWNTO 0); --array of coefficient * data products
	
END PACKAGE types;