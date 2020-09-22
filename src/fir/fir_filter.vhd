--------------------------------------------------------------------------------
--
--   FileName:         fir_filter.vhd
--   Dependencies:     types.vhd
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
USE work.types.all;

ENTITY fir_filter IS
	PORT(
			clk				:	IN		STD_LOGIC;                                  --system clock
			reset_n			:	IN		STD_LOGIC;                                  --active low asynchronous reset
			data				:	IN		STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);    --data stream
			coefficients	:	IN		coefficient_array;                          --coefficient array
			result			:	OUT	STD_LOGIC_VECTOR((data_width + coeff_width + integer(ceil(log2(real(taps)))) - 1) DOWNTO 0));  --filtered result
END fir_filter;

ARCHITECTURE behavior OF fir_filter IS
	SIGNAL coeff_int 		: coefficient_array; --array of latched in coefficient values
	SIGNAL data_pipeline : data_array;        --pipeline of historic data values
	SIGNAL products 		: product_array;     --array of coefficient*data products
BEGIN

	PROCESS(clk, reset_n)
		VARIABLE sum : SIGNED((data_width + coeff_width + integer(ceil(log2(real(taps)))) - 1) DOWNTO 0); --sum of products
	BEGIN
	
		IF(reset_n = '0') THEN                                       --asynchronous reset
		
			data_pipeline <= (OTHERS => (OTHERS => '0'));               --clear data pipeline values
			coeff_int <= (OTHERS => (OTHERS => '0'));		               --clear internal coefficient registers
			result <= (OTHERS => '0');                                  --clear result output
			
		ELSIF(clk'EVENT AND clk = '1') THEN                          --not reset

			coeff_int <= coefficients;												--input coefficients		
			data_pipeline <= SIGNED(data) & data_pipeline(0 TO taps-2);	--shift new data into data pipeline

			sum := (OTHERS => '0');                                     --initialize sum
			FOR i IN 0 TO taps-1 LOOP
				sum := sum + products(i);                                --add the products
			END LOOP;
			
			result <= STD_LOGIC_VECTOR(sum);	                           --output result
			
		END IF;
	END PROCESS;
	
	--perform multiplies
	product_calc: FOR i IN 0 TO taps-1 GENERATE
		products(i) <= data_pipeline(i) * SIGNED(coeff_int(i));
	END GENERATE;
	
END behavior;