-------------------------------------------------------------------------------
--
-- Title       : I2S_Transmitter
-- Design      : audio_effect
-- Author      : Wiktor Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\PISO.vhd
-- Generated   : Fri Dec 18 13:04:35 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : This entity is a I2S interface transmitter module. 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {I2S_Transmitter} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;

entity I2S_Transmitter is
	generic (data_width : positive range 16 to 24 := 24);
	Port ( CLK : in STD_LOGIC;									-- clock
		CE : in STD_LOGIC;										-- clock enable
		RESET : in STD_LOGIC;								  	-- asynchronous reset
		LRCK : in STD_LOGIC;								  	-- Left Right Clock.
		R_IN : in STD_LOGIC_VECTOR(data_width - 1 downto 0);  	-- Right channel input. It is load on falling edge of LRCK
		L_IN : in  STD_LOGIC_VECTOR(data_width - 1 downto 0); 	-- Left channel input. It is load on rising edge of LRCK
		SCLK : in STD_LOGIC;								  	-- Serial Clock for I2S.
		SDOUT : out STD_LOGIC);								    -- Seriad Data Out. This value is changed on falling edges of SCLK and must be stable
																-- on rising edge of SCLK
end I2S_Transmitter;


--}} End of automatically maintained section

architecture behavioral of I2S_Transmitter is	
	
	signal data_reg : std_logic_vector(data_width-1 downto 0); 	-- shift register to store R_IN and L_IN values.
	
begin	 
	
	process(CLK, RESET)
		variable lrck_reg, sclk_reg : std_logic_vector(1 downto 0);		-- variables used to detect changes on SCLK and LRCK lines. 
	begin
		if RESET = '1' then
			data_reg <= (others => '0');
			lrck_reg := (others => '0');
			sclk_reg := (others => '0');
		elsif rising_edge(CLK) then	  
			if CE = '1' then
				lrck_reg := lrck_reg(0) & LRCK;
				sclk_reg := sclk_reg(0) & SCLK;
				if lrck_reg = "01" then									 -- if LRCK changed from 0 to 1 load L_IN
					data_reg <= L_IN;		   
				elsif lrck_reg = "10" then 								 -- if LRCK changed from 1 to 0 load R_IN
					data_reg <= R_IN;
				elsif sclk_reg = "10" then
					data_reg <= data_reg(data_reg'high-1 downto 0) & '0';-- shift bits in data_reg 
				end if;		
			end if;	
		end if;	  
	end process;
	
	SDOUT <= data_reg(data_reg'high);  							   		 -- put consecutive data bits on SDOUT pin
	
end behavioral;
