-------------------------------------------------------------------------------
--
-- Title       : delay_effect
-- Design      : audio_effect
-- Author      : Wiktor Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\delay_effect.vhd
-- Generated   : Wed Dec 23 22:18:19 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : This entity contain delay effect description.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {delay_effect} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;		   
use IEEE.numeric_std.all;

entity delay_effect is 
	generic(data_width : integer := 24;
		mem_depth : integer := 65536; -- 2^16 										 	
		min_delay : integer := 1023); -- (2^10 - 1) * (max delay setting value = 2^5 -1) * (number of channels = 2) < (mem_depth = 2^16)  
	port(
		CLK : in STD_LOGIC;				  						-- Clock
		RESET : in STD_LOGIC;								    -- asynchronous Reset
		CE : in STD_LOGIC;										-- Clock Enable
		
		SETTING : in STD_LOGIC_VECTOR(7 downto 0);			  	-- setting value
		SETTING_LOAD : in STD_LOGIC_VECTOR(7 downto 0);		    -- setting address
		
		L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);	 	-- Left Channel input
		R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);	    -- Right Channel input
		L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);	-- Left Channel output
		R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);	-- Right Channel output
		
		LRCK_IN : in STD_LOGIC;   							    -- Left Right Clock input - edges of this signal indicate that data should be read
		LRCK_OUT : out STD_LOGIC							    -- Left Right Clock output - edges of this signal indicates that data is ready and can be read by next component
		);
end delay_effect;

--}} End of automatically maintained section

architecture behavioral of delay_effect is 	 

	-- when SETTING_LOAD matches c_on_off_setting, c_time_setting or c_volume_setting the corresponding vlaue is read from SETTING bus
	constant c_on_off_setting : std_logic_vector(7 downto 0) := X"41";
	constant c_on_code : std_logic_vector(7 downto 0 ) := X"01";
	constant c_off_code : std_logic_vector(7 downto 0) := X"00";
	
	constant c_time_setting : std_logic_vector(7 downto 0) := X"42";
	constant c_volume_setting : std_logic_vector(7 downto 0) := X"43";
	
	type mem_type is array(mem_depth-1 downto 0) of signed(data_width-1 downto 0);
	signal mem : mem_type;														  	-- buffer for incoming samples
	
	signal r_in_sig, l_in_sig : signed(data_width-1 downto 0);
	signal delay_time_usig : unsigned(4 downto 0) := "01000";						-- delay time
	signal vol_div_int : integer range 0 to 7 := 3;			 					    -- volume of delayed signal depends on this value
	
	signal is_on : boolean := false; 												-- indicate if effect is on or off
	
begin																
		
	r_in_sig <= SIGNED(R_IN);
	l_in_sig <= SIGNED(L_IN); 
	
	-- settings load
	process(CLK, RESET)
	begin
		if RESET = '1' then
			delay_time_usig <= "10000";
			vol_div_int <= 3;
		elsif rising_edge(CLK) then
			if CE = '1' then  
				if SETTING_LOAD = c_time_setting then	  								-- if pattern on SETTING_LOAD bus matches any setting code then load corresponding setting
					delay_time_usig <= unsigned(SETTING(6 downto 2)) + 1; 				-- with value from SETTING bus
				elsif SETTING_LOAD = c_volume_setting then
					vol_div_int <= to_integer(unsigned(not SETTING(6 downto 4)));	
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
	
	-- signal processing
	process(CLK, RESET)	
		variable mem_pointer : natural range 0 to mem_depth-1 := 0;	
		variable lrck_reg : std_logic_vector(1 downto 0) := "00";
	begin
		if RESET = '1' then
			lrck_reg := "00";
		elsif RISING_EDGE(CLK) then	 
			if CE = '1' then	   
				if is_on then
					lrck_reg := lrck_reg(0) & LRCK_IN;
					if lrck_reg = "01" then
						mem((mem_pointer + 2*min_delay*to_integer(delay_time_usig)) mod mem_depth) <= shift_right(l_in_sig, vol_div_int);  -- current value is shifted to decrase amplitude
						L_OUT <= std_logic_vector(l_in_sig + mem(mem_pointer));															   --  and stored in buffer	afterwards.
						mem_pointer := mem_pointer + 1;
						LRCK_OUT <=	'1';																								   -- outut value is sum of present input and value from previous samples buffer
					elsif lrck_reg = "10" then
						mem((mem_pointer + 2*min_delay*to_integer(delay_time_usig)) mod mem_depth) <= shift_right(r_in_sig, vol_div_int);	
						R_OUT <= std_logic_vector(r_in_sig + mem(mem_pointer));
						mem_pointer := mem_pointer + 1;	  
						LRCK_OUT <= '0';
					end if;	 
				else
					L_OUT <= L_IN;
					R_OUT <= R_IN;
					LRCK_OUT <= LRCK_IN;
				end if;	
			end if;
		end if;	
	end process;
end behavioral;
