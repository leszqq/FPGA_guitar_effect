-------------------------------------------------------------------------------
--
-- Title       : prescaler
-- Design      : audio_effect
-- Author      : Wiktor	Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\prescaler.vhd
-- Generated   : Fri Dec 18 13:03:20 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : This component is a clock prescaler. Frequency of output clock(Q) is the CLK frequency divided by generic value 'n'.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {prescaler} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;

entity prescaler is
	generic ( n: natural := 512);  								-- divider value
	Port ( CLK : in STD_LOGIC; 									-- input clock
		CE : in STD_LOGIC;										-- clock enable
		RESET : in STD_LOGIC;									-- asynchronous reset
		Q : out STD_LOGIC);									-- output clock
end prescaler;

--}} End of automatically maintained section

architecture behavioral of prescaler is	   
	signal cnt: natural range 0 to n-1;							-- counter
	signal q_int: STD_LOGIC;
begin
	
	process(CLK, RESET)
	begin
		if RESET='1' then
			cnt <= 0;
			q_int <= '0';
		else
			if CLK'event and CLK='1' then
				if CE='1' then
					if cnt = n/2 - 1 then
						cnt <= 0;
						q_int <= not q_int;
					else					   					-- toggle Q value after every n/2 - 1 CLK cycles
						cnt <= cnt + 1;                    
					end if;    
				end if;                
			end if;            
		end if;
	end process;
	
	Q <= q_int; 
	
end behavioral;
