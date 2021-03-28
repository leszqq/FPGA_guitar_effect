-------------------------------------------------------------------------------
--
-- Title       : delay
-- Design      : audio_effect
-- Author      : Wiktor Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\delay.vhd
-- Generated   : Fri Dec 18 13:05:40 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : 	 This entity is used to enable other componenets after time delay.	
--					 The Q output goes high after k clock cycles
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {delay} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;

entity delay is
	generic (k : positive := 10);
	Port ( CLK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		CE : in STD_LOGIC;
		Q : buffer STD_LOGIC);							-- The Q output is initialy low and it goes high after k clock cycles
end delay;

--}} End of automatically maintained section

architecture behavioral of delay is		 
	signal cnt : natural range 0 to k; 					-- counter
	signal q_int : STD_LOGIC;
begin
	
	process(CLK, RESET)
	begin
		if RESET='1' then
			cnt <= 0;
			q_int <= '0';
		elsif rising_edge(CLK) then
			if CE='1' then
				if q_int='0' then
					if cnt = k then
						q_int <= '1';  					-- after k cycles q_int gets the '1' value 
					else
						cnt <= cnt + 1;
					end if;          
				end if;                              
			end if;     
		end if;                   
	end process;
	
	Q <= q_int;
	
end behavioral;
