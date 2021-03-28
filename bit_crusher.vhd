-------------------------------------------------------------------------------
--
-- Title       : bit_crusher
-- Design      : audio_effect
-- Author      : Wiktor	Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\bit_crusher.vhd
-- Generated   : Fri Dec 25 16:36:06 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : This entity realize bit crusher effect. It is implemented by greatly downsampling
--				 incoming data. Sampling rate of output signal is the original sampling rate divied by frame_len_int.	 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {bit_crusher} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

entity bit_crusher is
	generic(data_width : integer := 24);
	port(
		CLK : in STD_LOGIC;	 											-- Clock
		CE : in STD_LOGIC;											    -- Clock Enable
		RESET : in STD_LOGIC;										    -- asynchronous Reset	 
		
		SETTING : in STD_LOGIC_VECTOR(7 downto 0);					    -- value of setting
		SETTING_LOAD : in STD_LOGIC_VECTOR(7 downto 0);				    -- address of setting to laod

		L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);			 	-- Left channel input
		R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);			    -- Right channel input
		L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);			-- Left channel output
		R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);		    -- Right channel ooutput	
		
		LRCK_IN : in STD_LOGIC;											-- Left Right Clock signal input ( indicate that left or right channel value can be read)
		LRCK_OUT : out STD_LOGIC										-- Left Right Clock signal output ( indicate that value on right or left channel output is valid )
	);
end bit_crusher;

--}} End of automatically maintained section

architecture behavioral of bit_crusher is	

	-- when SETTING_LOAD matches c_on_off_setting or c_frame_len_setting the corresponding vlaue is read from SETTING bus
	constant c_on_off_setting : std_logic_vector(7 downto 0) := X"01";
	constant c_on_code : std_logic_vector(7 downto 0) := X"01";
	constant c_off_code : std_logic_vector(7 downto 0) := X"00";  
	
	constant c_frame_len_setting : std_logic_vector(7 downto 0) := X"02";
	
	signal frame_len_int : integer range 0 to 63;				    	-- setting corresponding to downsampling ratio
	signal is_on : boolean;						  						-- indicate if effect is on or off
	signal cnt_r, cnt_l : natural range 0 to 63;   				    	-- counters
	
begin
	
	-- signal processing
	process(CLK, RESET)	 
		variable lrck_reg : std_logic_vector(1 downto 0);	
	begin
		if RESET = '1' then
			lrck_reg := "00";
			cnt_r <= 0;
			cnt_l <= 0;	

		elsif rising_edge(CLK) then
			if CE = '1' then
				if is_on then		
					lrck_reg := lrck_reg(0) & LRCK_IN;
					if lrck_reg = "10" then	  
						if cnt_r >= frame_len_int then	  					-- update output value every "frame_len_int" input values received
							cnt_r <= 0;
							R_OUT <= R_IN;		
						else
							cnt_r <= cnt_r + 1;
						end if;	
						LRCK_OUT <= LRCK_IN;
					elsif lrck_reg = "01" then
						if cnt_l >= frame_len_int then
							cnt_l <= 0;														  
							L_OUT <= L_IN;   								
						else
							cnt_l <= cnt_l + 1;
						end if;	
						LRCK_OUT <= LRCK_IN;
					end if;	
				else
					L_OUT <= L_IN; 											-- if effect is off map input ports to the outputs, so module becomes transparent
					R_OUT <= R_IN;
					LRCK_OUT <= LRCK_IN;
				end if;	
			end if;	
		end if;	   
	end process;
	
	-- settings load
	process(CLK, RESET)
	begin
		if RESET ='1' then
			frame_len_int <= 31;	 												-- default settings
			is_on <= false;	
		elsif rising_edge(CLK) then
			if CE = '1' then
				if SETTING_LOAD = c_frame_len_setting then			   				-- if value on SETTING_LOAD bus matches any effect setting then update this setting
					frame_len_int <= to_integer(unsigned(SETTING(6 downto 2)));	  	-- with value from SETTING bus
				elsif SETTING_LOAD = c_on_off_setting then
					if SETTING = c_on_code then
						is_on <= true;
					else
						is_on <= false;
					end if;	
				end if;	
			end if;
		end if;
	end process;
	
end behavioral;
