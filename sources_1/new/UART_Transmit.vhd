library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity UART_Transmit is
    Port (
        sysClk          :in std_logic;
        baudClkEn       :in std_logic;
        reset           :in std_logic;
        save            :in std_logic;
        dataReady       :in std_logic;  --Keyboard controller interface
        keyboardBuf     :in std_logic_vector(7 downto 0);
        typedASCII      :in std_logic_vector(55 downto 0);
        dataReceived    :out std_logic;
        iX              :in std_logic_vector(7 downto 0);   --ADC controller interface
        iY              :in std_logic_vector(7 downto 0);
        RAMbusy         :in std_logic;  --RAM controller interface
        updateNow       :out std_logic;
        eraseNow        :out std_logic;
        RX              :in std_logic;  --UART interface
        TX              :out std_logic    
    );
end UART_Transmit;
architecture Behavioral of UART_Transmit is
type machine is (ready, keyboardOpcode, erase, argumentSend, 
        coordOpcode, waitForRAM, coordSend1, coordSend2, saveCode,  
        ASCIIsend, sendStart, s0, s1, s2, s3, s4, s5, s6, s7, sendStop);
signal state, returnTo  :machine:= ready;
signal currentByte, currentX, currentY  :std_logic_vector(7 downto 0);
signal currentChar :integer:=0;
begin
    process(sysClk, reset)
    begin
        if(reset = '1') then
            TX <= '1';
            currentByte <= "00000000";
            updateNow <= '0';
            eraseNow <= '0';
            dataReceived <= '0';
            state <= ready;
        elsif(rising_edge(sysClk) and baudClkEn = '1') then
            case state is
                when ready =>
                eraseNow <= '0';
                    if(dataReady = '1' and keyboardBuf = "01010101") then -- Send Preamble
                        currentByte <= keyboardBuf;
                        dataReceived <= '1';
                        returnTo <= keyboardOpcode;
                        state <= sendStart;
                    elsif(save = '1') then
                        currentByte <= "01010101";
                        returnTo <= saveCode;
                        state <= sendStart;
                    elsif(RAMbusy = '0' and (iX /= currentX or iY /= currentY)) then
                        currentByte <= "01010101";
                        returnTo <= coordOpcode;
                        state <= sendStart;
                    end if;
                    
                when keyboardOpcode =>
                    if(keyboardBuf = "11110000") then --the "Erase" Opcode
                        currentByte <= keyboardBuf;
                        dataReceived <= '1';
                        returnTo <= erase;
                        state <= sendStart;
                    elsif(keyboardBuf = "10101010") then --the Setting Update Opcode
                        currentByte <= keyboardBuf;
                        dataReceived <= '1';
                        returnTo <= argumentSend;
                        state <= sendStart;
                    elsif(keyboardBuf = "00110011") then --the ASCII Update Opcode
                        currentByte <= keyboardBuf;
                        dataReceived <= '1';
                        currentChar <= 0;
                        returnTo <= ASCIIsend;
                        state <= sendStart;
                    else --Bad opcode received
                        state <= ready;    
                    end if;
                    state <= sendStart;
                    
                when erase =>
                    if(RAMbusy = '0') then
                        eraseNow <= '1';
                        state <= ready;
                    end if;
                    
                when argumentSend =>
                    currentByte <= keyboardBuf;
                    dataReceived <= '1';
                    returnTo <= argumentSend;
                    state <= sendStart;
                    
                when coordOpcode =>
                    currentByte <= "11001100"; --The Coordinate Update opcode
                    returnTo <= waitForRAM;
                    state <= sendStart;
                    
                when waitForRAM =>
                    if(RAMbusy = '0') then
                        state <= coordSend1;
                    end if;
                    
                when coordSend1 => --Send X
                    updateNow <= '1';                
                    currentByte <= iX;
                    currentX <= iX;
                    currentY <= iY;
                    returnTo <= coordSend2;
                    state <= sendStart; 
                    
                when coordSend2 => --Send Y
                    currentByte <= currentY;
                    returnTo <= ready;
                    state <= sendStart;
                    
                when ASCIIsend =>
                    case currentChar is
                        when 1 => currentByte <= typedASCII(55 downto 48);
                        when 2 => currentByte <= typedASCII(47 downto 40);
                        when 3 => currentByte <= typedASCII(39 downto 32);
                        when 4 => currentByte <= typedASCII(31 downto 24);
                        when 5 => currentByte <= typedASCII(23 downto 16);
                        when 6 => currentByte <= typedASCII(15 downto 8);
                        when 7 => currentByte <= typedASCII(7 downto 0);
                        when others => currentByte <= "01000000"; --@                                                                      
                    end case;
                    if(currentChar = 7) then
                        returnTo <= ready;
                    else
                        returnTo <= ASCIIsend;
                    end if;
                    state <= sendStart;
                
                when saveCode =>
                    if(save = '0') then
                        currentByte <= "10011001"; -- Save Opcode
                        returnTo <= ready;
                        state <= sendStart;
                    end if;
                    
                --Sub-State Machine for UART TX Control
                when sendStart =>
                    dataReceived <= '0';
                    eraseNow <= '0';
                    updateNow <= '0';
                    TX <= '0';
                    state <= s0;
                when s0 =>
                    TX <= currentByte(0);
                    state <= s1;
                when s1 =>
                    TX <= currentByte(1);
                    state <= s2;
                when s2 =>
                    TX <= currentByte(2);
                    state <= s3;
                when s3 =>
                    TX <= currentByte(3);
                    state <= s4;
                when s4 =>
                    TX <= currentByte(4);
                    state <= s5;
                when s5 =>
                    TX <= currentByte(5);
                    state <= s6;
                when s6 =>
                    TX <= currentByte(6);
                    state <= s7;
                when s7 =>
                    TX <= currentByte(7);
                    state <= sendStop;
                when sendStop =>
                    TX <= '1';
                    if(returnTo = argumentSend and dataReady = '0') then
                        state <= waitForRAM; --Send coordinates after keyboard settings update
                        --important for updating cursor color or size after a setting change.
                    elsif(returnTo = ASCIIsend) then --When sending the 7 ASCII characters of the command word
                        currentChar <= currentChar + 1; --Next character to be sent
                        state <= returnTo;
                    else
                        state <= returnTo;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
