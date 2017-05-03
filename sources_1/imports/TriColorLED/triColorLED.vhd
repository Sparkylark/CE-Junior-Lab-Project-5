library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity triColorLED is
	port(	CLK			: in std_logic;
			redIn		: in std_logic_vector(7 downto 0);
			greenIn 	: in std_logic_vector(7 downto 0);
			blueIn		: in std_logic_vector(7 downto 0);
			redOut		: out std_logic;
			greenOut	: out std_logic;
			blueOut		: out std_logic);
end triColorLED;

architecture Behavioral of triColorLED is

signal counter		: std_logic_vector(7 downto 0) := x"00";

begin

process(CLK) -- counter
begin
	if rising_edge(CLK) then
		if counter = 256 then
			counter <= x"00";
		else
			counter <= counter + x"01";
		end if;
	end if;
end process;

redOut <= '1' when (counter < redIn) else '0';
greenOut <= '1' when (counter < greenIn) else '0';
blueOut <= '1' when (counter < blueIn) else '0';
end architecture;