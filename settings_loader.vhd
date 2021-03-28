-------------------------------------------------------------------------------
--
-- Title       : settings_loader
-- Design      : audio_effect
-- Author      : Wiktor	Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\settings_loader.vhd
-- Generated   : Mon Jan  4 15:10:17 2021
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description :	This entity maintain loading settings to effects. 
--					It gets setting code or setting value on data pin. The cotrol
--					bit indicate value on D_IN bus is a settign value or setting code
--					When setting value is received it is preserved on D_OUT bus.
--					Next the setting code load should be obtained. Obtained setting code
--					is passed to SETTINGS_LOAD output for one clock cycle and matching 
--					settings is laod by one of effect modules.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {settings_loader} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;

entity settings_loader is
	 port(
		 CLK : in STD_LOGIC;  											-- Clock
		 CE : in STD_LOGIC;											    -- Clock Enable
		 RESET : in STD_LOGIC;										    -- asynchronous Reset
		 CONTROL_BIT : in STD_LOGIC;									-- 0 if D_OUT is setting value, 1 if D_OUT is setting address
		 D_IN : in STD_LOGIC_VECTOR(6 downto 0); 						-- data received from UART
		 D_IN_LOAD : in STD_LOGIC;									    -- received data load
		 SETTINGS_LOAD : out STD_LOGIC_VECTOR(7 downto 0);			    -- address of effect setting to load
		 D_OUT : out STD_LOGIC_VECTOR(7 downto 0)						-- setting value
	     );
end settings_loader;

--}} End of automatically maintained section

architecture behavioral of settings_loader is  

	constant c_load_null : STD_LOGIC_VECTOR(7 downto 0) := X"00";		-- there is no setting corresponding to this address. 

begin

	process(CLK, RESET)
	begin
		if RESET = '1' then
			D_OUT <= (others => '0');
			SETTINGS_LOAD <= (others => '0');
		elsif rising_edge(CLK) then
			if CE = '1' then
				if D_IN_LOAD = '1' then
					if CONTROL_BIT = '1' then							
						SETTINGS_LOAD <= '0' & D_IN;					-- when new byte is received and it is a setting address then write it on SETTING_LOAD bus for one clock cycle																			
					elsif CONTROL_BIT = '0' then						
						D_OUT <= '0' & D_IN;						  	-- else when new byte is received and it is a setting value then preserve it on the D_OUT bus
					end if;
				else
					SETTINGS_LOAD <= c_load_null; 
				end if;	
			end if;
		end if;
	end process;

end behavioral;
