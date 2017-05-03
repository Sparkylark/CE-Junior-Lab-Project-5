library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use ieee.std_logic_unsigned.all;

entity clk_enabler is
	GENERIC (
		CONSTANT cnt_max : integer := 49999999); -- 1 second
	port(	
		clock:		in std_logic;
		Reset:      in std_logic; 
		clk_en: 	out std_logic
	);
end clk_enabler;

----------------------------------------------------

architecture behv of clk_enabler is

signal clk_cnt: integer range 0 to cnt_max;
	 
begin

	process(clock, Reset)
	begin
	if (Reset = '1') then
	   clk_cnt <= 0;
	elsif rising_edge(clock) then
		if (clk_cnt = cnt_max) then
			clk_cnt <= 0;
			clk_en <= '1';
		else
			clk_cnt <= clk_cnt + 1;
			clk_en <= '0';
		end if;
	end if;
	end process;

end behv;
