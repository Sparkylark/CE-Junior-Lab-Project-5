library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity lcd_Wrapper is
	port(	CLK			: in std_logic;
			reset		: in std_logic;
			colorLong	: in std_logic_vector(23 downto 0);
			width_in	: in std_logic_vector(2 downto 0);
			size		: in std_logic;
			typedString	: in std_logic_vector(55 downto 0);
			e			: out std_logic;
			rs			: out std_logic;
			rw			: out std_logic;
			data_out	: out std_logic_vector(7 downto 0));
end lcd_Wrapper;

architecture behavioural of lcd_Wrapper is

component lcd_controller IS
  PORT(
    clk        : IN    STD_LOGIC;  --system clock
    reset_n    : IN    STD_LOGIC;  --active low reinitializes lcd
    lcd_enable : IN    STD_LOGIC;  --latches data into lcd controller
    lcd_bus    : IN    STD_LOGIC_VECTOR(9 DOWNTO 0);  --data and control signals
    busy       : OUT   STD_LOGIC := '1';  --lcd controller busy/idle feedback
    rw, rs, e  : OUT   STD_LOGIC;  --read/write, setup/data, and enable for lcd
    lcd_data   : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
END component;

type STATE_TYPE is (ready, sendData1, sendData2);
signal state			: STATE_TYPE := ready;
--signal data				: std_logic_vector(7 downto 0) := "00000000";
signal data             : std_logic_vector(9 downto 0) := "0000000000";
signal busy				: std_logic;
signal lcdEnable		: std_logic;
signal reset_n          : std_logic;
signal change           : std_logic;
signal counter			: integer := 0;

signal lcdDisplayString	: std_logic_vector(55 downto 0);
signal lcdWidth			: std_logic_vector(7 downto 0);
signal lcdSize			: std_logic_vector(7 downto 0);
signal red				: std_logic_vector(15 downto 0);
signal green			: std_logic_vector(15 downto 0);
signal blue				: std_logic_vector(15 downto 0);
begin
reset_n <= not reset;
--dataCtrl <= "10" & data;

inst_lcd: lcd_controller
	port map(	clk 		=> CLK,
				reset_n 	=> reset_n, -- active low
				lcd_enable 	=> lcdEnable,
				lcd_bus		=> data,
				busy		=> busy,
				rw			=> rw,
				rs			=> rs,
				e			=> e,
				lcd_data	=> data_out);

process(CLK)
begin
	if rising_edge(CLK) then
		case state is
			when ready =>
				if busy = '0' then
					state <= sendData1;
				end if;
			when sendData1 => -- enable LCD
				lcdEnable <= '1';
				state <= sendData2;
			when sendData2 => -- increment counter
				lcdEnable <= '0';
				if counter = 41 then
				    counter <= 0;
				else
				    counter <= counter + 1;
				end if;
				state <= ready;	    
		end case;
	end if;
end process;

process--sequence of data to output
begin
	case counter is
	    when 0 => data <= "00" & "10000000";--line 1
 		when 1 => data <= "10" & "01010011";--S--53
		when 2 => data <= "10" & "01101001";--i--69
		when 3 => data <= "10" & "01111010";--z--7A
		when 4 => data <= "10" & "01100101";--e--65
		when 5 => data <= "10" & "00111010";--:--3A
		when 6 => data <= "10" & lcdSize;--size data
		when 7 => data <= "10" & "00100000";--space
		
		when 8 => data <= "10" & "01001001";--I
		when 9 => data <= "10" & "01101110";--n
		when 10 => data <= "10" & "01110000";--p
		when 11 => data <= "10" & "01110101";--u
		when 12 => data <= "10" & "01110100";--t
		when 13 => data <= "10" & "00111010";--:
		when 14 => data <= "10" & lcdDisplayString(55 downto 48);--string data 1
		when 15 => data <= "10" & lcdDisplayString(47 downto 40);--string data 2
		when 16 => data <= "10" & lcdDisplayString(39 downto 32);--string data 3
		when 17 => data <= "10" & lcdDisplayString(31 downto 24);--string data 4
		when 18 => data <= "10" & lcdDisplayString(23 downto 16);--string data 5
		when 19 => data <= "10" & lcdDisplayString(15 downto 8);--string data 6
		when 20 => data <= "10" & lcdDisplayString(7 downto 0);--string data 7
		--next line
		when 21 => data <= "00" & "11000000";--line 2
		when 22 => data <= "10" & "01010111";--W
		when 23 => data <= "10" & "01101001";--i
		when 24 => data <= "10" & "01100100";--d
		when 25 => data <= "10" & "01110100";--t
		when 26 => data <= "10" & "01101000";--h
		when 27 => data <= "10" & "00111010";--:
		when 28 => data <= "10" & lcdWidth;--width data
		when 29 => data <= "10" & "00100000";--space
		
		when 30 => data <= "10" & "01010010";--R
		when 31 => data <= "10" & red(15 downto 8);--red 1 data
		when 32 => data <= "10" & red(7 downto 0);--red 2 data
		when 33 => data <= "10" & "00100000";--space
		
		when 34 => data <= "10" & "01000111";--G
		when 35 => data <= "10" & green(15 downto 8);--green 1 data
		when 36 => data <= "10" & green(7 downto 0);--green 2 data
		when 37 => data <= "10" & "00100000";--space
		
		when 38 => data <= "10" & "01000010";--B
		when 39 => data <= "10" & blue(15 downto 8);--blue 1 data
		when 40 => data <= "10" & blue(7 downto 0);--blue 2 data
		when others => data <= "10" & "00100000";
	end case;
end process;

process--convert vectors to lcd pointers
begin
	case typedString(55 downto 48) is --char 1
		when x"43" => lcdDisplayString(55 downto 48) <= "01000011"; -- C
		when x"45" => lcdDisplayString(55 downto 48) <= "01000101"; -- E
		when x"53" => lcdDisplayString(55 downto 48) <= "01010011"; -- S
		when x"57" => lcdDisplayString(55 downto 48) <= "01010111"; -- W
		when others => lcdDisplayString(55 downto 48) <= "00100000";
	end case;

	case typedString(47 downto 40) is --char 2
		when x"30" => lcdDisplayString(47 downto 40) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(47 downto 40) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(47 downto 40) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(47 downto 40) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(47 downto 40) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(47 downto 40) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(47 downto 40) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(47 downto 40) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(47 downto 40) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(47 downto 40) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(47 downto 40) <= "01000001"; -- A
		when x"42" => lcdDisplayString(47 downto 40) <= "01000010"; -- B
		when x"43" => lcdDisplayString(47 downto 40) <= "01000011"; -- C
		when x"44" => lcdDisplayString(47 downto 40) <= "01000100"; -- D
		when x"45" => lcdDisplayString(47 downto 40) <= "01000101"; -- E
		when x"46" => lcdDisplayString(47 downto 40) <= "01000110"; -- F
		when others => lcdDisplayString(47 downto 40) <= "00100000";
	end case;

	case typedString(39 downto 32) is --char 3
		when x"30" => lcdDisplayString(39 downto 32) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(39 downto 32) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(39 downto 32) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(39 downto 32) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(39 downto 32) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(39 downto 32) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(39 downto 32) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(39 downto 32) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(39 downto 32) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(39 downto 32) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(39 downto 32) <= "01000001"; -- A
		when x"42" => lcdDisplayString(39 downto 32) <= "01000010"; -- B
		when x"43" => lcdDisplayString(39 downto 32) <= "01000011"; -- C
		when x"44" => lcdDisplayString(39 downto 32) <= "01000100"; -- D
		when x"45" => lcdDisplayString(39 downto 32) <= "01000101"; -- E
		when x"46" => lcdDisplayString(39 downto 32) <= "01000110"; -- F
		when others => lcdDisplayString(39 downto 32) <= "00100000";
	end case;

	case typedString(31 downto 24) is --char 4
		when x"30" => lcdDisplayString(31 downto 24) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(31 downto 24) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(31 downto 24) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(31 downto 24) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(31 downto 24) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(31 downto 24) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(31 downto 24) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(31 downto 24) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(31 downto 24) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(31 downto 24) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(31 downto 24) <= "01000001"; -- A
		when x"42" => lcdDisplayString(31 downto 24) <= "01000010"; -- B
		when x"43" => lcdDisplayString(31 downto 24) <= "01000011"; -- C
		when x"44" => lcdDisplayString(31 downto 24) <= "01000100"; -- D
		when x"45" => lcdDisplayString(31 downto 24) <= "01000101"; -- E
		when x"46" => lcdDisplayString(31 downto 24) <= "01000110"; -- F
		when others => lcdDisplayString(31 downto 24) <= "00100000";
	end case;

	case typedString(23 downto 16) is --char 5
		when x"30" => lcdDisplayString(23 downto 16) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(23 downto 16) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(23 downto 16) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(23 downto 16) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(23 downto 16) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(23 downto 16) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(23 downto 16) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(23 downto 16) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(23 downto 16) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(23 downto 16) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(23 downto 16) <= "01000001"; -- A
		when x"42" => lcdDisplayString(23 downto 16) <= "01000010"; -- B
		when x"43" => lcdDisplayString(23 downto 16) <= "01000011"; -- C
		when x"44" => lcdDisplayString(23 downto 16) <= "01000100"; -- D
		when x"45" => lcdDisplayString(23 downto 16) <= "01000101"; -- E
		when x"46" => lcdDisplayString(23 downto 16) <= "01000110"; -- F
		when others => lcdDisplayString(23 downto 16) <= "00100000";
	end case;

	case typedString(15 downto 8) is --char 6
		when x"30" => lcdDisplayString(15 downto 8) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(15 downto 8) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(15 downto 8) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(15 downto 8) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(15 downto 8) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(15 downto 8) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(15 downto 8) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(15 downto 8) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(15 downto 8) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(15 downto 8) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(15 downto 8) <= "01000001"; -- A
		when x"42" => lcdDisplayString(15 downto 8) <= "01000010"; -- B
		when x"43" => lcdDisplayString(15 downto 8) <= "01000011"; -- C
		when x"44" => lcdDisplayString(15 downto 8) <= "01000100"; -- D
		when x"45" => lcdDisplayString(15 downto 8) <= "01000101"; -- E
		when x"46" => lcdDisplayString(15 downto 8) <= "01000110"; -- F
		when others => lcdDisplayString(15 downto 8) <= "00100000";
	end case;
	
	case typedString(7 downto 0) is --char 7
		when x"30" => lcdDisplayString(7 downto 0) <= "00110000"; -- 0
		when x"31" => lcdDisplayString(7 downto 0) <= "00110001"; -- 1
		when x"32" => lcdDisplayString(7 downto 0) <= "00110010"; -- 2
		when x"33" => lcdDisplayString(7 downto 0) <= "00110011"; -- 3
		when x"34" => lcdDisplayString(7 downto 0) <= "00110100"; -- 4
		when x"35" => lcdDisplayString(7 downto 0) <= "00110101"; -- 5
		when x"36" => lcdDisplayString(7 downto 0) <= "00110110"; -- 6
		when x"37" => lcdDisplayString(7 downto 0) <= "00110111"; -- 7
		when x"38" => lcdDisplayString(7 downto 0) <= "00111000"; -- 8
		when x"39" => lcdDisplayString(7 downto 0) <= "00111001"; -- 9
		when x"41" => lcdDisplayString(7 downto 0) <= "01000001"; -- A
		when x"42" => lcdDisplayString(7 downto 0) <= "01000010"; -- B
		when x"43" => lcdDisplayString(7 downto 0) <= "01000011"; -- C
		when x"44" => lcdDisplayString(7 downto 0) <= "01000100"; -- D
		when x"45" => lcdDisplayString(7 downto 0) <= "01000101"; -- E
		when x"46" => lcdDisplayString(7 downto 0) <= "01000110"; -- F
		when others => lcdDisplayString(7 downto 0) <= "00100000"; 
	end case;
	
	case width_in is--width
		when "001" => lcdWidth <= "00110001"; -- 1
		when "010" => lcdWidth <= "00110010"; -- 2
		when "011" => lcdWidth <= "00110011"; -- 3
		when "100" => lcdWidth <= "00110100"; -- 4
		when "101" => lcdWidth <= "00110101"; -- 5
		when "110" => lcdWidth <= "00110110"; -- 6
		when "111" => lcdWidth <= "00110111"; -- 7
		when others => lcdWidth <= "00110000"; -- 0
		end case;
	
	case size is--size
		when '0' => lcdSize <= "00110001"; -- 1
		when '1' => lcdSize <= "00110010"; -- 2
		when others => lcdSize <= "00110000"; -- 0
	end case;
	
	case colorLong(23 downto 20) is--color 1(red1)
		when "0000" => red(15 downto 8) <= "00110000"; -- 0
		when "0001" => red(15 downto 8) <= "00110001"; -- 1
		when "0010" => red(15 downto 8) <= "00110010"; -- 2
		when "0011" => red(15 downto 8) <= "00110011"; -- 3
		when "0100" => red(15 downto 8) <= "00110100"; -- 4
		when "0101" => red(15 downto 8) <= "00110101"; -- 5
		when "0110" => red(15 downto 8) <= "00110110"; -- 6
		when "0111" => red(15 downto 8) <= "00110111"; -- 7
		when "1000" => red(15 downto 8) <= "00111000"; -- 8
		when "1001" => red(15 downto 8) <= "00111001"; -- 9
		when "1010" => red(15 downto 8) <= "01000001"; -- A
		when "1011" => red(15 downto 8) <= "01000010"; -- B
		when "1100" => red(15 downto 8) <= "01000011"; -- C
		when "1101" => red(15 downto 8) <= "01000100"; -- D
		when "1110" => red(15 downto 8) <= "01000101"; -- E
		when "1111" => red(15 downto 8) <= "01000110"; -- F
		when others => red(15 downto 8) <= "00100000";		
	end case;
	
	case colorLong(19 downto 16) is--color 2(red2)
		when "0000" => red(7 downto 0) <= "00110000"; -- 0
		when "0001" => red(7 downto 0) <= "00110001"; -- 1
		when "0010" => red(7 downto 0) <= "00110010"; -- 2
		when "0011" => red(7 downto 0) <= "00110011"; -- 3
		when "0100" => red(7 downto 0) <= "00110100"; -- 4
		when "0101" => red(7 downto 0) <= "00110101"; -- 5
		when "0110" => red(7 downto 0) <= "00110110"; -- 6
		when "0111" => red(7 downto 0) <= "00110111"; -- 7
		when "1000" => red(7 downto 0) <= "00111000"; -- 8
		when "1001" => red(7 downto 0) <= "00111001"; -- 9
		when "1010" => red(7 downto 0) <= "01000001"; -- A
		when "1011" => red(7 downto 0) <= "01000010"; -- B
		when "1100" => red(7 downto 0) <= "01000011"; -- C
		when "1101" => red(7 downto 0) <= "01000100"; -- D
		when "1110" => red(7 downto 0) <= "01000101"; -- E
		when "1111" => red(7 downto 0) <= "01000110"; -- F
		when others => red(3 downto 0) <= "00100000";
	end case;
	
	case colorLong(15 downto 12) is--color 3(green1)
		when "0000" => green(15 downto 8) <= "00110000"; -- 0
		when "0001" => green(15 downto 8) <= "00110001"; -- 1
		when "0010" => green(15 downto 8) <= "00110010"; -- 2
		when "0011" => green(15 downto 8) <= "00110011"; -- 3
		when "0100" => green(15 downto 8) <= "00110100"; -- 4
		when "0101" => green(15 downto 8) <= "00110101"; -- 5
		when "0110" => green(15 downto 8) <= "00110110"; -- 6
		when "0111" => green(15 downto 8) <= "00110111"; -- 7
		when "1000" => green(15 downto 8) <= "00111000"; -- 8
		when "1001" => green(15 downto 8) <= "00111001"; -- 9
		when "1010" => green(15 downto 8) <= "01000001"; -- A
		when "1011" => green(15 downto 8) <= "01000010"; -- B
		when "1100" => green(15 downto 8) <= "01000011"; -- C
		when "1101" => green(15 downto 8) <= "01000100"; -- D
		when "1110" => green(15 downto 8) <= "01000101"; -- E
		when "1111" => green(15 downto 8) <= "01000110"; -- F
		when others => green(15 downto 8) <= "00100000";
	end case;
	
	case colorLong(11 downto 8) is--color 4(green2)
		when "0000" => green(7 downto 0) <= "00110000"; -- 0
		when "0001" => green(7 downto 0) <= "00110001"; -- 1
		when "0010" => green(7 downto 0) <= "00110010"; -- 2
		when "0011" => green(7 downto 0) <= "00110011"; -- 3
		when "0100" => green(7 downto 0) <= "00110100"; -- 4
		when "0101" => green(7 downto 0) <= "00110101"; -- 5
		when "0110" => green(7 downto 0) <= "00110110"; -- 6
		when "0111" => green(7 downto 0) <= "00110111"; -- 7
		when "1000" => green(7 downto 0) <= "00111000"; -- 8
		when "1001" => green(7 downto 0) <= "00111001"; -- 9
		when "1010" => green(7 downto 0) <= "01000001"; -- A
		when "1011" => green(7 downto 0) <= "01000010"; -- B
		when "1100" => green(7 downto 0) <= "01000011"; -- C
		when "1101" => green(7 downto 0) <= "01000100"; -- D
		when "1110" => green(7 downto 0) <= "01000101"; -- E
		when "1111" => green(7 downto 0) <= "01000110"; -- F
		when others => green(7 downto 0) <= "00100000";
	end case;
	
	case colorLong(7 downto 4) is--color 5(blue1)
		when "0000" => blue(15 downto 8) <= "00110000"; -- 0
		when "0001" => blue(15 downto 8) <= "00110001"; -- 1
		when "0010" => blue(15 downto 8) <= "00110010"; -- 2
		when "0011" => blue(15 downto 8) <= "00110011"; -- 3
		when "0100" => blue(15 downto 8) <= "00110100"; -- 4
		when "0101" => blue(15 downto 8) <= "00110101"; -- 5
		when "0110" => blue(15 downto 8) <= "00110110"; -- 6
		when "0111" => blue(15 downto 8) <= "00110111"; -- 7
		when "1000" => blue(15 downto 8) <= "00111000"; -- 8
		when "1001" => blue(15 downto 8) <= "00111001"; -- 9
		when "1010" => blue(15 downto 8) <= "01000001"; -- A
		when "1011" => blue(15 downto 8) <= "01000010"; -- B
		when "1100" => blue(15 downto 8) <= "01000011"; -- C
		when "1101" => blue(15 downto 8) <= "01000100"; -- D
		when "1110" => blue(15 downto 8) <= "01000101"; -- E
		when "1111" => blue(15 downto 8) <= "01000110"; -- F
		when others => blue(15 downto 8) <= "00100000";
	end case;
	
	case colorLong(3 downto 0) is--color 6(blue2)
		when "0000" => blue(7 downto 0) <= "00110000"; -- 0
		when "0001" => blue(7 downto 0) <= "00110001"; -- 1
		when "0010" => blue(7 downto 0) <= "00110010"; -- 2
		when "0011" => blue(7 downto 0) <= "00110011"; -- 3
		when "0100" => blue(7 downto 0) <= "00110100"; -- 4
		when "0101" => blue(7 downto 0) <= "00110101"; -- 5
		when "0110" => blue(7 downto 0) <= "00110110"; -- 6
		when "0111" => blue(7 downto 0) <= "00110111"; -- 7
		when "1000" => blue(7 downto 0) <= "00111000"; -- 8
		when "1001" => blue(7 downto 0) <= "00111001"; -- 9
		when "1010" => blue(7 downto 0) <= "01000001"; -- A
		when "1011" => blue(7 downto 0) <= "01000010"; -- B
		when "1100" => blue(7 downto 0) <= "01000011"; -- C
		when "1101" => blue(7 downto 0) <= "01000100"; -- D
		when "1110" => blue(7 downto 0) <= "01000101"; -- E
		when "1111" => blue(7 downto 0) <= "01000110"; -- F
		when others => blue(7 downto 0) <= "00100000";
	end case;
end process;
end behavioural;