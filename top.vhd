-------------------------------------------------------------------------------
--
-- Title       : 
-- Design      : audio_effect
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : c:\My_Designs\audio_effect\audio_effect\compile\top.vhd
-- Generated   : Tue Jan 19 09:46:41 2021
-- From        : c:\My_Designs\audio_effect\audio_effect\src\top.bde
-- By          : Bde2Vhdl ver. 2.6
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
-- Design unit header --
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_unsigned.all;

entity top is
  port(
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       RESET : in STD_LOGIC;
       RX : in STD_LOGIC;
       SDIN : in STD_LOGIC;
       LRCK_ADC : out STD_LOGIC;
       LRCK_DAC : out STD_LOGIC;
       MCLK_ADC : out STD_LOGIC;
       MCLK_DAC : out STD_LOGIC;
       SCLK_ADC : out STD_LOGIC;
       SCLK_DAC : out STD_LOGIC;
       SDOUT : out STD_LOGIC;
       led : out STD_LOGIC_VECTOR(6 downto 0)
  );
end top;

architecture structural of top is

---- Component declarations -----

component bit_crusher
  generic(
       data_width : INTEGER := 24
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       LRCK_IN : in STD_LOGIC;
       L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       RESET : in STD_LOGIC;
       R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       SETTING : in STD_LOGIC_VECTOR(7 downto 0);
       SETTING_LOAD : in STD_LOGIC_VECTOR(7 downto 0);
       LRCK_OUT : out STD_LOGIC;
       L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);
       R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0)
  );
end component;
component clock_generator
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       RESET : in STD_LOGIC;
       LRCK : out STD_LOGIC;
       MCLK : out STD_LOGIC;
       SCLK : out STD_LOGIC;
       TX_EN : out STD_LOGIC
  );
end component;
component delay_effect
  generic(
       data_width : INTEGER := 24;
       mem_depth : INTEGER := 65536;
       min_delay : INTEGER := 1023
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       LRCK_IN : in STD_LOGIC;
       L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       RESET : in STD_LOGIC;
       R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       SETTING : in STD_LOGIC_VECTOR(7 downto 0);
       SETTING_LOAD : in STD_LOGIC_VECTOR(7 downto 0);
       LRCK_OUT : out STD_LOGIC;
       L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);
       R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0)
  );
end component;
component flanger
  generic(
       data_width : INTEGER := 24
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       LRCK_IN : in STD_LOGIC;
       L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       RESET : in STD_LOGIC;
       R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       SETTING : in STD_LOGIC_VECTOR(7 downto 0);
       SETTINGS_LOAD : in STD_LOGIC_VECTOR(7 downto 0);
       LRCK_OUT : out STD_LOGIC;
       L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);
       R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0)
  );
end component;
component i2s_receiver
  generic(
       data_width : POSITIVE range 16 to 24 := 24
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       LRCK_IN : in STD_LOGIC;
       RESET : in STD_LOGIC;
       SCLK : in STD_LOGIC;
       SDIN : in STD_LOGIC;
       LRCK_OUT : out STD_LOGIC;
       L_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0);
       R_OUT : out STD_LOGIC_VECTOR(data_width-1 downto 0)
  );
end component;
component I2S_Transmitter
  generic(
       data_width : POSITIVE range 16 to 24 := 24
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       LRCK : in STD_LOGIC;
       L_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       RESET : in STD_LOGIC;
       R_IN : in STD_LOGIC_VECTOR(data_width-1 downto 0);
       SCLK : in STD_LOGIC;
       SDOUT : out STD_LOGIC
  );
end component;
component settings_loader
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       CONTROL_BIT : in STD_LOGIC;
       D_IN : in STD_LOGIC_VECTOR(6 downto 0);
       D_IN_LOAD : in STD_LOGIC;
       RESET : in STD_LOGIC;
       D_OUT : out STD_LOGIC_VECTOR(7 downto 0);
       SETTINGS_LOAD : out STD_LOGIC_VECTOR(7 downto 0)
  );
end component;
component uart_receiver
  generic(
       baud_period_in_cycles : NATURAL := 10417
  );
  port (
       CE : in STD_LOGIC;
       CLK : in STD_LOGIC;
       RESET : in STD_LOGIC;
       RX : in STD_LOGIC;
       D_OUT : out STD_LOGIC_VECTOR(7 downto 0) := "00000000";
       D_VALID : out STD_LOGIC := '0'
  );
end component;

---- Signal declarations used on the diagram ----

signal CLR120 : STD_LOGIC;
signal CLR154 : STD_LOGIC;
signal CLR1712 : STD_LOGIC;
signal CLR1752 : STD_LOGIC;
signal CLR221 : STD_LOGIC;
signal CLR281 : STD_LOGIC;
signal LRCK : STD_LOGIC;
signal MCLK : STD_LOGIC;
signal TX_EN : STD_LOGIC;
signal D : STD_LOGIC_VECTOR(7 downto 0);
signal L0 : STD_LOGIC_VECTOR(23 downto 0);
signal L1 : STD_LOGIC_VECTOR(23 downto 0);
signal L2 : STD_LOGIC_VECTOR(23 downto 0);
signal L3 : STD_LOGIC_VECTOR(23 downto 0);
signal R0 : STD_LOGIC_VECTOR(23 downto 0);
signal R1 : STD_LOGIC_VECTOR(23 downto 0);
signal R2 : STD_LOGIC_VECTOR(23 downto 0);
signal R3 : STD_LOGIC_VECTOR(23 downto 0);
signal SETTING : STD_LOGIC_VECTOR(7 downto 0);
signal SETTING_LOAD : STD_LOGIC_VECTOR(7 downto 0);

begin

----  Component instantiations  ----

SCLK_ADC <= CLR120;

U10 : uart_receiver
  port map(
       CE => CE,
       CLK => CLK,
       D_OUT => D,
       D_VALID => CLR221,
       RESET => RESET,
       RX => RX
  );

U11 : settings_loader
  port map(
       CE => CE,
       CLK => CLK,
       CONTROL_BIT => D(7),
       D_IN(0) => D(0),
       D_IN(1) => D(1),
       D_IN(2) => D(2),
       D_IN(3) => D(3),
       D_IN(4) => D(4),
       D_IN(5) => D(5),
       D_IN(6) => D(6),
       D_IN_LOAD => CLR221,
       D_OUT => SETTING,
       RESET => RESET,
       SETTINGS_LOAD => SETTING_LOAD
  );

U12 : delay_effect
  generic map(
       data_width => 24
  )
  port map(
       CE => CE,
       CLK => CLK,
       LRCK_IN => CLR281,
       LRCK_OUT => CLR154,
       L_IN => L2(23 downto 0),
       L_OUT => L3(23 downto 0),
       RESET => RESET,
       R_IN => R2(23 downto 0),
       R_OUT => R3(23 downto 0),
       SETTING => SETTING,
       SETTING_LOAD => SETTING_LOAD
  );

MCLK_DAC <= MCLK;

led(6) <= SETTING(6);

led(5) <= SETTING(5);

led(4) <= SETTING(4);

led(3) <= SETTING(3);

led(2) <= SETTING(2);

LRCK_ADC <= LRCK;

led(1) <= SETTING(1);

led(0) <= SETTING(0);

MCLK_ADC <= MCLK;

U30 : flanger
  port map(
       CE => CE,
       CLK => CLK,
       LRCK_IN => CLR1752,
       LRCK_OUT => CLR1712,
       L_IN => L0(23 downto 0),
       L_OUT => L1(23 downto 0),
       RESET => RESET,
       R_IN => R0(23 downto 0),
       R_OUT => R1(23 downto 0),
       SETTING => SETTING,
       SETTINGS_LOAD => SETTING_LOAD
  );

U4 : clock_generator
  port map(
       CE => CE,
       CLK => CLK,
       LRCK => LRCK,
       MCLK => MCLK,
       RESET => RESET,
       SCLK => CLR120,
       TX_EN => TX_EN
  );

SCLK_DAC <= CLR120;

U6 : i2s_receiver
  generic map(
       data_width => 24
  )
  port map(
       CE => CE,
       CLK => CLK,
       LRCK_IN => LRCK,
       LRCK_OUT => CLR1752,
       L_OUT => L0(23 downto 0),
       RESET => RESET,
       R_OUT => R0(23 downto 0),
       SCLK => CLR120,
       SDIN => SDIN
  );

U7 : I2S_Transmitter
  generic map(
       data_width => 24
  )
  port map(
       CE => TX_EN,
       CLK => CLK,
       LRCK => CLR154,
       L_IN => L3(23 downto 0),
       RESET => RESET,
       R_IN => R3(23 downto 0),
       SCLK => CLR120,
       SDOUT => SDOUT
  );

LRCK_DAC <= CLR154;

U9 : bit_crusher
  port map(
       CE => CE,
       CLK => CLK,
       LRCK_IN => CLR1712,
       LRCK_OUT => CLR281,
       L_IN => L1(23 downto 0),
       L_OUT => L2(23 downto 0),
       RESET => RESET,
       R_IN => R1(23 downto 0),
       R_OUT => R2(23 downto 0),
       SETTING => SETTING,
       SETTING_LOAD => SETTING_LOAD
  );


end structural;
