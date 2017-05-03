library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity Keyboard_Decode is
  Port (CLK             : in std_logic;    
        pulse           : in std_logic;
        Data            : in std_logic_vector(7 downto 0);
        dataReceived    : in std_logic;
        reset           : in std_logic;
        size            : out std_logic;
        width           : out std_logic_vector(2 downto 0);
        color           : out std_logic_vector(7 downto 0);
        colorLongOut    : out std_logic_vector(23 downto 0);
        dataReady       : out std_logic;
        oBuffer         : out std_logic_vector(7 downto 0);
        typedString     : out std_logic_vector(55 downto 0) := x"20202020202020");
end Keyboard_Decode;

architecture Behavioral of Keyboard_Decode is

type STATE_TYPE is (start, enterC, enterS, enterW, enterE, receiveHV, receiveEnt, enterWait, receive12, receive17);
type SEND_TYPE is (sendStart,preamble55, preambleAA, redS, greenS, blueS, cursorS, EpreambleF0, Apreamble33);
Signal state            : STATE_TYPE := start;
Signal returnTo         : STATE_TYPE := start;
Signal returnToR        : STATE_TYPE := start;
Signal sendState        : SEND_TYPE := sendStart;
Signal nextSendState    : SEND_TYPE := sendStart;

Signal red              : std_logic_vector(7 downto 0);
Signal green            : std_logic_vector(7 downto 0);
Signal blue             : std_logic_vector(7 downto 0);
Signal colorLong        : std_logic_vector(23 downto 0);

Signal widthTemp        : std_logic_vector(2 downto 0);
Signal sizeTemp         : std_logic_vector(0 downto 0);

Signal read             : std_logic;
Signal receiveBytes     : integer := 0;

Signal eraseFlag        : std_logic;

Signal changed          : std_logic := '0';

Signal pulseTemp        : std_logic_vector(1 downto 0) := "00";
Signal asciiUpdate      : std_logic := '0';

Signal dataReceivedTemp : std_logic_vector(1 downto 0) := "00";

Signal widthBuf         :std_logic_vector(2 downto 0);
Signal sizeBuf          :std_logic:='0';  
begin


size <= sizeBuf;
width <= widthBuf;

Process(CLK)
begin
    if rising_edge(CLK) then
            pulseTemp(1) <= pulseTemp(0);
            pulseTemp(0) <= pulse;
            dataReceivedTemp(1) <= dataReceivedTemp(0);
            dataReceivedTemp(0) <= dataReceived;
    end if;
end process;

Process(CLK)
begin
    if rising_edge(CLK) then
        if reset = '1' then
            --changed <= '1';
            colorLong <= x"000000";
            color <= x"00";
            red <= x"00";
            green <= x"00";
            blue <= x"00";
            
            widthTemp <= "001";
            widthBuf <= "001";
            sizeTemp <= "0";
            sizeBuf <= '0';
            eraseFlag <= '0';
           
            state <= start;
            returnTO <= start;
            returnTOR <= start;
            
            typedString <= x"20202020202020";
        else
            -- watch state to control update ascii flag
            if sendState = Apreamble33 then--and dataReceived = '1' then
                asciiUpdate <= '0';
            end if;
            case state is
                when start =>
                    if pulseTemp = "01" then
                        if Data = x"43" then -- C
                            state <= enterC;
                            typedString(55 downto 48) <= x"43";
                            asciiUpdate <= '1';
                        elsif Data = x"53" then -- S
                            state <= enterS;
                            typedString(55 downto 48) <= x"53";
                            asciiUpdate <= '1';
                        elsif Data = x"57" then -- W
                            state <= enterW;
                            typedString(55 downto 48) <= x"57";
                            asciiUpdate <= '1';
                        elsif Data = x"45" then -- E
                            state <= enterE;
                            typedString(55 downto 48) <= x"45";
                            asciiUpdate <= '1';
                        else
                            state <= start;
                        end if;
                    else
                        state <= start;
                    end if;
                    
        --***************** Change Color block **************************
                when enterC => 
                    if read = '1' then
                        read <= '0';
                        typedString <= x"20202020202020";
                        colorLongOut <= colorLong;
                        red <= colorLong(23 downto 16);
                        green <= colorLong(15 downto 8);
                        blue <= colorLong(7 downto 0);
                        color(7 downto 5) <= colorLong(23 downto 21);
                        color(4 downto 2) <= colorLong(15 downto 13);
                        color(1 downto 0) <= colorLong(7 downto 6); 
                        state <= start;
                    else
                        state <= receiveHV;
                        returnTo <= enterC;
                        receiveBytes <= 7;
                    end if;
                    
        --***************** Change Size block ***************************
                when enterS =>
                    if read = '1' then
                        read <= '0';
                        sizeBuf <= sizeTemp(0);
                        typedString <= x"20202020202020";
                        state <= start;
                    else
                        state <= receive12;
                        returnTo <= enterS;
                        receiveBytes <= 7;
                    end if;
                 
        --***************** Change Width block **************************
                when enterW => 
                    if read = '1' then
                        read <= '0';
                        widthBuf <= widthTemp;
                        typedString <= x"20202020202020";
                        state <= start;
                    else
                        state <= receive17;
                        returnTo <= enterW;
                        receiveBytes <= 7;
                    end if;
                
        --***************** Erase feild block ***************************            
                when enterE => 
                    --eraseFlag <= '1';
                    if read = '1' then
                        read <= '0';
                        typedString <= x"20202020202020";
                        state <= start;
                    else
                        state <= receiveEnt;
                        receiveBytes <= 7;
                        returnToR <= start;
                        returnTo <= enterE;
                    end if;
                
        --***************** Recieves ************************************        
                when receiveHV =>
                    if pulseTemp = "01" then
                        asciiUpdate <= '1';
                        case Data is
                            when x"30" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"0";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"31" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"1";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"32" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"2";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"33" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"3";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"34" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"4";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"35" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"5";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"36" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"6";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"37" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"7";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"38" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"8";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"39" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"9";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"41" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"A";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"42" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"B";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"43" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"C";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"44" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"D";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"45" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"E";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"46" =>
                                receiveBytes <= receiveBytes - 1;
                                colorLong((((receiveBytes-1)*4)-1) downto (((receiveBytes-1)*4)-4)) <= x"F";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"5C" =>
                                if(receiveBytes<7) then 
                                    receiveBytes <= receiveBytes + 1;
                                    colorLong((((receiveBytes)*4)-1) downto (((receiveBytes)*4)-4)) <= x"0";
                                    typedString((((receiveBytes)*8)-1) downto (((receiveBytes)*8)-8)) <= x"20";
                                elsif(receiveBytes = 7) then
                                    colorLong(23 downto 0) <= x"000000";
                                    typedString(55 downto 0) <= x"20202020202020";
                                    state <= start;
                                end if;
                            when others => 
                                asciiUpdate <= '0';
                        end case;
                    end if;
                    if receiveBytes = 1 then --4569705yug7yeu
                        state <= receiveEnt;
                        returnToR <= receiveHV;
                    end if;

                when receive17 =>
                    if pulseTemp = "01" then
                        asciiUpdate <= '1';
                        case Data is
                            when x"31" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "001";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"32" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "010";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"33" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "011";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"34" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "100";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"35" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "101";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"36" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "110";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"37" =>
                                receiveBytes <= receiveBytes - 1;
                                widthTemp <= "111";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                            when x"5C" =>
                                receiveBytes <= receiveBytes + 1;
                                widthTemp <= "001";
                                typedString(55 downto 0) <= x"20202020202020";
                                state <= start;
                            when others => 
                                asciiUpdate <= '0';
                        end case;
                    end if;
                    if receiveBytes = 6 then 
                        state <= receiveEnt;
                        returnToR <= receive17;
                    end if;
                    
                when receive12 =>
                    if pulseTemp = "01" then
                        asciiUpdate <= '1';
                        case Data is
                            when x"31" =>
                                receiveBytes <= receiveBytes - 1;
                                sizeTemp <= "0";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                                state <= receiveEnt;
                                returnToR <= receive12;
                            when x"32" =>
                                receiveBytes <= receiveBytes - 1;
                                sizeTemp <= "1";
                                typedString((((receiveBytes-1)*8)-1) downto (((receiveBytes-1)*8)-8)) <= Data;
                                state <= receiveEnt;
                                returnToR <= receive12;
                            when x"5C" => 
                                receiveBytes <= receiveBytes + 1;
                                sizeTemp <= "0";
                                typedString(55 downto 0) <= x"20202020202020";
                                state <= start;
                            when others => 
                                asciiUpdate <= '0';
                        end case;
                    end if;
                
                                    
                when receiveEnt =>
                    if pulseTemp = "01" then
                        case Data is
                            when x"2F" =>
                                if(returnTo = enterE) then --arrived here due to Erase
                                    eraseFlag <= '1';
                                    state <= enterWait;
                                else
                                    changed <= '1';
                                    state <= enterWait;
                                end if;
                            when x"5C" =>
                                state <= returnToR;
                                receiveBytes <= receiveBytes + 1;
                                typedString((((receiveBytes)*8)-1) downto (((receiveBytes)*8)-8)) <= x"20";
                                asciiUpdate <= '1';
                            when others =>    
                        end case;
                    end if;
                
                    when enterWait =>
                        if (sendState = preambleAA or sendState = EpreambleF0) then
                            read <= '1'; 
                            state <= returnTo;
                            changed <= '0';
                            eraseFlag <= '0';
                        end if;    
                            
                when others => state <= start;
            end case;  
        end if;
    end if;  
end process;

Process(CLK, dataReceived)
begin
    if rising_edge(CLK)then-- combine into one state machine
        case sendState is
            when sendStart =>
                dataReady <= '0';
                if changed = '1' then
                    sendState <= preamble55;
                    nextSendState <= preambleAA;
                elsif eraseFlag = '1' then -- erasedFlag
                    sendState <= preamble55;
                    nextSendState <= EpreambleF0;
                elsif asciiUpdate = '1' then -- asciiUpdate
                    sendState <= preamble55;
                    nextSendState <= Apreamble33;
                end if;
            when preamble55 =>
                oBuffer <= x"55";
                dataReady <= '1';
                if dataReceivedTemp = "01" then
                    sendState <= nextSendState;
                end if;
  -------------- Erase Update --------------------------------------             
            when EpreambleF0 =>
                oBuffer <= x"F0";
                if dataReceivedTemp = "01" then
                    sendState <= sendStart;
                    dataReady <= '0';
                end if;   
  -------------- ASCII Update --------------------------------------              
            when Apreamble33 =>
                oBuffer <= x"33";
                if dataReceivedTemp = "01" then
                    sendState <= sendStart;
                    dataReady <= '0';
                end if;    
  ------------- Cursor Update --------------------------------------              
            when preambleAA =>
                oBuffer <= x"AA";
                if dataReceivedTemp = "01" then
                    sendState <= redS;
                end if;
            when redS =>
                oBuffer <= red;
                if dataReceivedTemp = "01" then
                    sendState <= greenS;
                end if;
            when greenS =>
                oBuffer <= green;
                if dataReceivedTemp = "01" then
                    sendState <= blueS;
                end if;
            when blueS =>
                oBuffer <= blue;
                if dataReceivedTemp = "01" then
                    sendState <= cursorS;
                end if;
            when cursorS =>
                oBuffer(7 downto 5) <= widthBuf;
                oBuffer(4) <= sizeBuf;
                --oBuffer(3 downto 3) <= eraseFlag; 
                oBuffer(3 downto 0) <= "0000";
                if dataReceivedTemp = "01" then
                    sendState <= sendStart;
                    dataReady <= '0';
                end if;
            when others => sendState <= sendStart;
        end case;
    end if;
end process;
end Behavioral;
