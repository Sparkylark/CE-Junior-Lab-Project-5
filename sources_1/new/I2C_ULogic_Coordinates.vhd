library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity I2C_ULogic_Coordinates is
    Port ( 	
				iClk            :in std_logic;
				iReset		    :in std_logic;
				oReset_n        :out std_logic;
				ena			    :out std_logic;
				addr			:out std_logic_vector(6 downto 0);
				rw				:out std_logic;
				data_rd         :in std_logic_vector(7 downto 0);
				data_wr	        :out std_logic_vector(7 downto 0);
				ack_error	    :buffer std_logic;
				busy			:in std_logic;
				X               :out std_logic_vector(7 downto 0);
				Y               :out std_logic_vector(7 downto 0)
				);
end I2C_ULogic_Coordinates;

architecture Behavioral of I2C_ULogic_Coordinates is

type machine is(start, configure, readByte1, readByte2, processRead);
signal state : machine;
signal busyPrev         :std_logic:='1';
signal readRegister     :std_logic_vector(15 downto 0);

begin
process(iClk, iReset, ack_error)
begin
	if (iReset = '1' or ack_error = '1') then
	--if (iReset_n = '0' and resetPrev = '1') or reset_Delay = '1' then
		state <= start;
		oReset_n <= '0';
		ena <= '0';
		X <= x"00";
		Y <= x"00";
		data_wr <= x"00";
	elsif rising_edge(iClk) then
        case state is
            when start =>
                oReset_n <= '1';
                ena <= '1';
                addr <= "0101000"; --Address of PmodAD2
                rw <= '0';
                data_wr <= "00110000"; --Use channels 0 and 1 on ADC
                if(busy = '1' and busyPrev = '0') then
                    state <= configure;
                end if;
            when configure =>
                rw <= '1';
                if(busy = '1' and busyPrev = '0') then
                    state <= readByte1;
                end if;        
            when readByte1 =>
                if(busy = '0' and busyPrev = '1') then
                    readRegister(15 downto 8) <= data_rd;
                    state <= readByte2;
                end if;
            when readByte2 =>
                if(busy = '0' and busyPrev = '1') then
                    readRegister(7 downto 0) <= data_rd;
                    state <= processRead;
                end if;
            when processRead =>
                if(readRegister(15 downto 14)/= "00") then
                    state <= start; --this occurs if the two read bytes get swapped somehow
                else
                    if(readRegister(12) = '0') then
                        X <= readRegister(11 downto 4);
                    else
                        Y <= readRegister(11 downto 4);
                    end if;
                    state <= readByte1;
                end if;
		end case;
		end if;
end process;

process(iClk)
begin
    if(rising_edge(iClk)) then
        busyPrev <= busy;
    end if;
end process;

end Behavioral;