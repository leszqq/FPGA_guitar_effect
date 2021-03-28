-------------------------------------------------------------------------------
--
-- Title       : UART_Receiver
-- Design      : audio_effect
-- Author      : Wiktor	Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\UART_Receiver.vhd
-- Generated   : Mon Dec 28 17:37:10 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description :  This entity containt UART_Receiver module.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {UART_Receiver} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;   
use IEEE.numeric_std.all;

entity UART_Receiver is
	generic(baud_period_in_cycles : natural := 10417);	  	-- calculate this as CLK frequency divided by baud rate.
	 port(
		 CLK : in STD_LOGIC;					   					-- Clock 
		 CE : in STD_LOGIC;								  			-- Clock Enable
		 RESET : in STD_LOGIC;									  	-- asynchronous Reset
		 RX : in STD_LOGIC;								   			-- received data is present on this RX pin
		 D_VALID : out STD_LOGIC;									-- high for 1 clock cycle after reveiving a byte
		 D_OUT : out STD_LOGIC_VECTOR(7 downto 0)					-- received data
	     );
end UART_Receiver;

--}} End of automatically maintained section

architecture behavioral of UART_Receiver is	  
	signal anti_meta_cnt : natural range 0 to 99;
begin

	process(CLK, RESET)
	variable RX_reg : std_logic_vector(1 downto 0) := "00";	 		-- this variable is used to detect UART start condition ( falling edge on RX line )
	variable cnt : natural range 0 to 16000 := 0;	 				-- counter to measure time until RX pin should be read.
	variable data_index : natural range 0 to 8 := 0;				-- indicate data index of next value present on RX pin
	variable waiting : boolean := true;		  						-- true when receiver is waiting for start condition
	begin
		if RESET = '1' then
			cnt := 0;
			data_index := 0;
			RX_reg := "00";			   
			waiting := true;
			D_OUT <= (others => '0');
			D_VALID <= '0';
			anti_meta_cnt <= 0;
		elsif RISING_EDGE(CLK) then
			if CE = '1' then
				D_VALID <= '0';
				if waiting then				 						-- if waiting for start condition, check if value on RX pin changed from 1 to 0	
					if anti_meta_cnt < 99 then	 					-- RX falling edge is indepedent from the CLK signal. State of this line is checked 
						anti_meta_cnt <= anti_meta_cnt + 1;			-- with frequency anti_meta_n times smaller than CLK frequency to minimize the probability
					else											-- of occuring metastability anti_meta_n times. 
						anti_meta_cnt <= 0;
						RX_reg := RX_reg(0) & RX;
						if RX_reg = "10" then
							waiting := false;
							data_index := 0;
							cnt := 0;
						end if;			   
					end if;	
				else	   
					if data_index = 0 then
						if cnt >= 3 * (baud_period_in_cycles/2) then  -- when receiving the MSB wait for 1.5 * ( 1 / (baud rate) ) 
							D_OUT(data_index) <= RX;
							data_index := data_index + 1;
							cnt := 0;
						end if;	    
					else
						if cnt >= baud_period_in_cycles then   		  -- read next bits when counter overflows
							D_OUT(data_index) <= RX; 
							data_index := data_index + 1;
							cnt := 0; 
							if data_index > 7 then
								waiting := true;				 	 -- put '1' value on D_VALID output after receiveing a byte for one clock period.
								D_VALID <= '1';
							end if;	       
						end if;	    
					end if;	
					cnt := cnt + 1;
				end if;	
			end if;
		end if;	
	end process;
end behavioral;
