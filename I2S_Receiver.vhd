												 -------------------------------------------------------------------------------
--
-- Title       : I2S_Receiver
-- Design      : audio_effect
-- Author      : Wiktor Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\SIPO.vhd
-- Generated   : Tue Dec 22 21:50:39 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : This entity is a I2S interface receiver module.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {I2S_Receiver} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;

entity I2S_Receiver is
	generic( data_width :  positive range 16 to 24 := 24);
	 port(
		 CLK : in STD_LOGIC;  										-- Clock
		 CE : in STD_LOGIC;											-- Clock Enable
		 RESET : in STD_LOGIC;										-- asynchronous Reset
		 LRCK_IN : in STD_LOGIC;								  	-- Left Right Clock Input  - received data
		 LRCK_OUT : out STD_LOGIC;									-- Left Right Clock Output - received data
		 SDIN : in STD_LOGIC;									  	-- Serial Data In
		 SCLK : in STD_LOGIC;									  	-- Serial Clock
		 R_OUT : out STD_LOGIC_VECTOR(data_width - 1 downto 0);	  	-- Right channel Out
		 L_OUT : out STD_LOGIC_VECTOR(data_width - 1 downto 0)	    -- Left channel Out
	     );
end I2S_Receiver;

--}} End of automatically maintained section

architecture behavioral of I2S_Receiver is	 
	signal reg : std_logic_vector(data_width - 1 downto 0); 	   		-- register to store incoming serial data
	signal d_valid_flag : std_logic;									-- flag to indicate that all bits of word has been received
begin		  
	
	-- this process is used to store incoming data in internal register
	process(CLK, RESET)	  
	variable data_index : integer range -2 to data_width - 1 := 0;		-- this variable is used to indicate 23 to 0 bit index in incoming data.
																		-- - 1 value indicate that all bit has been received and data_valid_flag should be set.
																		-- - 2 value indicate that data is already present on L_OUT or R_OUT bus.
	variable sclk_reg, lrck_reg : std_logic_vector(1 downto 0) := "00";	-- variables used to detect changes on SCLK and LRCK lines.  
	begin
		if RESET = '1' then
			reg <= (others => '0');
			d_valid_flag <= '0';
		elsif rising_edge(CLK) then	
			if CE = '1' then	  
				sclk_reg := sclk_reg(0) & SCLK;	 
				lrck_reg := lrck_reg(0) & LRCK_IN;
				if lrck_reg(1) /= lrck_reg(0) then						-- after lrck change data_index gets generic value "data_width". 
					data_index := data_width - 1;
				elsif sclk_reg = "01" then								-- on change from 0 to 1 on SCLK line next bit is stored in reg
					if data_index >= 0 then
						reg(data_index) <= SDIN;
						data_index := data_index - 1;
					elsif data_index = -1 then							-- when all the bits have been received d_valid_flag is set
						d_valid_flag <= '1';
						data_index := data_index - 1;
					else
						d_valid_flag <= '0';
					end if;	
				end if;	
			end if;		
		end if;
	end process; 
	
	-- value on L_OUT and R_OUT buses is updated inside this process.
	process(CLK, RESET)
	variable sclk_reg : std_logic_vector(1 downto 0);	 				-- variables used to detect changes on SCLK line.  
	begin
		if RESET = '1' then 
			L_OUT <= (others => '0');
			R_OUT <= (others => '0');
			sclk_reg := "00";
		elsif rising_edge(CLK) then	  
			if CE = '1' then
				sclk_reg := sclk_reg(0) & SCLK;	 						-- if 24 bits of data have been received update L_OUT or R_OUT bus and update LRCK_OUT line 
				if sclk_reg = "10" then									-- to indicate that left or right channel value is present on L_OUT or R_OUT bus
					if d_valid_flag = '1' then	
						if LRCK_IN = '1' then
							L_OUT <= reg;
							LRCK_OUT <= '1';
						else
							R_OUT <= reg;
							LRCK_OUT <= '0';
						end if;	  
					end if;		 
				end if;		
			end if;	
		end if;
	end process;
	
end behavioral;
