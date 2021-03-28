-------------------------------------------------------------------------------
--
-- Title       : flanger
-- Design      : audio_effect
-- Author      : Wiktor Lechowicz
-- Company     : AGH University Of Science
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\src\flanger.vhd
-- Generated   : Tue Dec 29 15:08:02 2020
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {flanger} architecture {behavioral}}

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;	   	 
use IEEE.math_real.all;

entity flanger is
	generic(data_width : integer := 24);
	port(
		CLK : in STD_LOGIC;	 									-- Clock
		CE : in STD_LOGIC;								   		-- Clock Enable
		RESET : in STD_LOGIC;		 						 	-- Reset
		SETTING : in STD_LOGIC_VECTOR(7 downto 0);	  			-- setting value
		SETTINGS_LOAD : in STD_LOGIC_VECTOR(7 downto 0);		-- setting address / load
		L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);	  	-- Left Channel input
		R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);	  	-- Right Channel input
		L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);  	-- Left Channel output
		R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);  	-- Right Channel output
		LRCK_IN : in STD_LOGIC;								  	-- Left Right Clock input
		LRCK_OUT : out STD_LOGIC								-- Left Right Clock output
		);
end flanger;

--}} End of automatically maintained section

architecture behavioral of flanger is	 

	-- when SETTING_LOAD matches c_on_off_setting, c_mix_setting, c_depth_setting or c_rate_setting the corresponding vlaue is read from SETTING bus
	constant c_on_off_setting : std_logic_vector(7 downto 0) := X"21";
	constant c_on_code : std_logic_vector(7 downto 0 ) := X"01";
	constant c_off_code : std_logic_vector(7 downto 0) := X"00";  
	
	constant c_mix_setting : std_logic_vector(7 downto 0) := X"22";
	constant c_depth_setting : std_logic_vector(7 downto 0) := X"23";
	constant c_rate_setting : std_logic_vector(7 downto 0) := X"24";
	
	constant MIX_SHIFT : integer := 4;				
	constant FRAC_SHIFT : integer := 16;
	
	constant NN : integer := 16;		-- length of addres
	constant WL : integer := 15;	  	-- LUT word length	 
	constant MAX_ROM_VAL : real := 32000.0;
	constant ROM_OFFSET : real := 20.0;
	constant MAX_SIN_VAL : integer := 64040;
	type rom_type is array(0 to (2**NN)-1) of unsigned(WL-1 downto 0);	  			--	2^NN cells of size WL	  
	
	-- this is function for initializing LUT with values of function y = 1 - cos(x) (only first quadrant)
	function init_rom return rom_type is			  	
		constant N: integer := 2**NN;
		constant Nr : real := real(N);
		variable w, kr : real;
		variable memx : rom_type;
	begin
		for k in 0 to N-1 loop
			kr := (real(k)+0.5)/Nr;													-- 0.5 offset to keep sinusoid symetric
			w := 1.0 - cos(math_pi_over_2 * kr);									-- evalueate next value
			memx(k) :=  to_unsigned(integer(round(MAX_ROM_VAL*w + ROM_OFFSET)), WL);-- scale to WL bit unsigned
		end loop;	
		return memx;
	end function init_rom;	 
	
	constant sin_lut : rom_type := init_rom;										-- LUT for function: y = 1 - cos(x)	
	
	constant mem_depth : integer := 256; 											-- length of sample buffers
	type mem_type is array(0 to mem_depth-1) of signed(data_width-1 downto 0);	 
	
	-- this is function for initializing LUT with values of function y = 1 - cos(x) (only first quadrant)
	function init_buff return mem_type is			  	
		variable buffx : mem_type;
	begin
		for k in 0 to mem_depth-1 loop
			buffx(k) := to_signed(0, 24);
		end loop;	
		return buffx;
	end function init_buff;	
	
	signal l_buff, r_buff : mem_type := init_buff;--(others => signed(std_logic_vector("000000000000000000000000")));				-- buffers for left and right channel samples	  
		
	-- effect settings
	signal rate_usig : unsigned(5 downto 0);
	signal depth_usig : unsigned(7 downto 0);   
	signal mix_sig, one_minus_mix_sig : signed(4 downto 0);		
	signal is_on : boolean;
	
	signal l_in_sig, r_in_sig : signed(data_width-1 downto 0);	  
	
begin  
	
	l_in_sig <= signed(L_IN);
	r_in_sig <= signed(R_IN); 
	
	-- settings load
	process(CLK, RESET)
	begin			
		if RESET = '1' then																		-- default effect settings
			mix_sig <= "01000";
			one_minus_mix_sig <= "00111";
			depth_usig <= X"41";	   -- 40
			rate_usig <= "001000";
			is_on <= false;
		elsif rising_edge(CLK) then
			if CE = '1' then
				if SETTINGS_LOAD = c_mix_setting then											-- if pattern on SETTING_LOAD bus matches any setting code then update corresponding
					mix_sig <= signed('0' & SETTING(6 downto 3));							   	-- setting with value from SETTING bus	
					if SETTING(6 downto 3) /= X"0" then	   										-- calculate 1 - mix 
						one_minus_mix_sig <= signed('0' & (unsigned(not SETTING(6 downto 3)) + 1));		 
					else
						one_minus_mix_sig <= "01111";  
					end if;	
				elsif SETTINGS_LOAD = c_depth_setting then
					depth_usig <= unsigned('0' & SETTING(6 downto 0));	
				elsif SETTINGS_LOAD = c_rate_setting then
					rate_usig <= unsigned('0' & SETTING(6 downto 3) & '0');		-- "00" i reszta potem
				elsif SETTINGS_LOAD = c_on_off_setting then
					if SETTING = c_on_code then
						is_on <= true;
					elsif SETTING = c_off_code then
						is_on <= false;
					end if;
				end if;
			end if;	
		end if;
	end process;
	
	-- signal processing
	process(CLK, RESET)	  
		variable p : unsigned(NN+1 downto 0);  													-- pointer to LUT cell
		variable lrck_reg : std_logic_vector(1 downto 0);
		variable delay : unsigned(23 downto 0);													-- fixed point format 8.16 	  
		variable lb_ptr, rb_ptr : integer range 0 to mem_depth-1;								-- pointers decrements at every lrck cycle
		variable i : unsigned(7 downto 0);														-- integer part of delay. format 8.0
		variable frac : signed(16 downto 0);							  						-- fraction part of delay. format 0.16	
		variable one_minus_frac : signed(16 downto 0);											-- 1 - frac. format 0.16					
		variable tmp_cnt : integer range 0 to 15 := 0;

	begin
		if RESET = '1' then							   
			p := (others => '0');
			lrck_reg := "00";
			lb_ptr := mem_depth-1;
			rb_ptr := mem_depth-1;	   
		elsif rising_edge(CLK) then
			if CE = '1' then   
				if is_on then
					lrck_reg := lrck_reg(0) & LRCK_IN;
					
					if lrck_reg = "01" then	  
						
						-- calculate delay time based on LUT containing values of first quadrant of y(x) = 1 - cos(x) function
						case p(p'high downto p'high-1) is		  
							when "00" => delay := depth_usig*
							('0' & sin_lut(to_integer(p(p'high-2  downto 0))));
							when "01" => delay := depth_usig*
							(to_unsigned(MAX_SIN_VAL, WL+1) - ('0' & sin_lut(2**NN - 1 - to_integer(p(p'high-2 downto 0)))));
							when "10" => delay := depth_usig*
							(to_unsigned(MAX_SIN_VAL, WL+1) - ('0' & sin_lut(to_integer(p(p'high-2  downto 0)))));	 
							when "11" => delay := depth_usig*
							('0' & sin_lut(2**NN - 1 - to_integer(p(p'high-2  downto 0))));
							when others => delay := (others => '0');	 
						end case;		  
						
						-- increment pointer to next delay value   
						p := p + rate_usig;	
						
						
						-- get integer and fraction part of delay time
						i := delay(23 downto 16);
						frac := signed('0' & delay(15 downto 0));
						one_minus_frac := signed('0' & (not(delay(15 downto 0)) + 1));
						
						-- save incoming input in buffer and calculate output value as y[n] = (1-mix)*x[n] + mix*(x[n+(i+1)]*frac + x[n+i]*(1-frac))
						-- indexing is opposite to description in documentation to simplify implementation of circular buffer.
						l_buff(lb_ptr) <= l_in_sig;	    
						
						L_OUT <= std_logic_vector( shift_right(l_in_sig*one_minus_mix_sig, MIX_SHIFT)(23 downto 0) +
						shift_right( mix_sig*( shift_right(l_buff( (lb_ptr + to_integer(i) + 1) mod mem_depth )*frac, FRAC_SHIFT)(23 downto 0) + 
						shift_right(l_buff( (lb_ptr + to_integer(i)) mod mem_depth )*one_minus_frac, FRAC_SHIFT)(23 downto 0) ), MIX_SHIFT)(23 downto 0) );	
	
						LRCK_OUT <= '1';
						lb_ptr  := (lb_ptr - 1) mod mem_depth;
	
					elsif lrck_reg = "10" then
						r_buff(rb_ptr) <= r_in_sig;
						
						R_OUT<= std_logic_vector( shift_right(r_in_sig*one_minus_mix_sig, MIX_SHIFT)(23 downto 0) +
						shift_right( mix_sig*( shift_right(r_buff( (rb_ptr + to_integer(i) + 1) mod mem_depth )*frac, FRAC_SHIFT)(23 downto 0) + 
						shift_right(r_buff( (rb_ptr + to_integer(i)) mod mem_depth )*one_minus_frac, FRAC_SHIFT)(23 downto 0) ), MIX_SHIFT)(23 downto 0) );
						
						LRCK_OUT <= '0';
						rb_ptr  := (rb_ptr - 1) mod mem_depth;				
					end if;	
				else
					-- If effect is off, map the input signal ports to output signal ports.
					L_OUT <= L_IN;
					R_OUT <= R_IN;
					LRCK_OUT <= LRCK_IN;	
				end if;	
			end if;
		end if;
	end process;

end behavioral;
