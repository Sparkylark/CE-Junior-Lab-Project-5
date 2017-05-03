library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Controller is
    Port ( 
        sysClk          :in std_logic;
        reset           :in std_logic;
        refreshPulse    :in std_logic;
        color           :in std_logic_vector(7 downto 0);
        width           :in std_logic_vector(2 downto 0);
        size            :in std_logic;
        typedASCII      :in std_logic_vector(55 downto 0);
        sketchReadAddr  :out std_logic_vector(15 downto 0);
        sketchOut       :in std_logic_vector(7 downto 0);
        CGaddr          :out std_logic_vector(8 downto 0);
        CGout           :in std_logic_vector(7 downto 0);
        VGA_R           :out std_logic_vector(3 downto 0);
        VGA_G           :out std_logic_vector(3 downto 0);
        VGA_B           :out std_logic_vector(3 downto 0);
        VGA_VS          :out std_logic;
        VGA_HS          :out std_logic 
    );
end VGA_Controller;

architecture Behavioral of VGA_Controller is
signal Hcounter, Vcounter       :integer:= 0;
signal HcounterNext, VcounterNext   :integer := 0;
type machine is (wait1, sketchS1, sketchS2, wait2, statusLine, printLetterRow, wordLine);
signal state, returnTo          :machine:= wait1;
signal currentSend              :std_logic_vector(7 downto 0):= "00000000";
signal nextXaddr, nextYaddr     :integer:=0;
signal CGletter                   :std_logic_vector(5 downto 0);
signal whichLetter              :integer:=0;
signal endLetter                :integer:=0;
signal nextCharPixel            :integer:=0;
signal letterRow                :std_logic_vector(2 downto 0);
signal VGA_out                  :std_logic_vector(7 downto 0);


begin

--CGRom partial address controller - Determined by whichLetter, which is controlled
--by printLetterRow and the states that directly enter it, statusLine and wordLine.
CGletter <= "000011" when whichLetter = 0 else -- C
            "010101" when whichLetter = 1 else -- U
            "010010" when whichLetter = 2 else -- R
            "010011" when whichLetter = 3 else -- S
            "001111" when whichLetter = 4 else -- O
            "010010" when whichLetter = 5 else -- R
            "101101" when whichLetter = 6 else -- -
            std_logic_vector("110000" + unsigned("000" & width)) when whichLetter = 7 else
            "100000" when whichLetter = 8 else -- " "
            "100000" when whichLetter = 9 else -- " "
            "100000" when whichLetter = 10 else -- " "
            "000011" when whichLetter = 11 else -- C
            "001111" when whichLetter = 12 else -- O
            "001100" when whichLetter = 13 else -- L
            "001111" when whichLetter = 14 else -- O
            "010010" when whichLetter = 15 else -- R
            "101101" when whichLetter = 16 else -- -
            "010111" when whichLetter = 17 else -- W
            "001111" when whichLetter = 18 else -- 0
            "010010" when whichLetter = 19 else -- R
            "000100" when whichLetter = 20 else -- D
            "101101" when whichLetter = 21 else -- -
            typedASCII(53 downto 48) when whichLetter = 22 else
            typedASCII(45 downto 40) when whichLetter = 23 else
            typedASCII(37 downto 32) when whichLetter = 24 else
            typedASCII(29 downto 24) when whichLetter = 25 else
            typedASCII(21 downto 16) when whichLetter = 26 else
            typedASCII(13 downto 8) when whichLetter = 27 else
            typedASCII(5 downto 0) when whichLetter = 28 else
            "000000";
            
----CGROM Addressing Case Statement
--process(sysClk)
--begin
--    case whichLetter is
--        when 0 => CGletter <= "000011"; -- C
--        when 1 => CGletter <= "010101"; -- U
--        when 2 => CGletter <= "010010"; -- R
--        when 3 => CGletter <= "010011"; -- S
--        when 4 => CGletter <= "001111"; -- O
--        when 5 => CGletter <= "010010"; -- R
--        when 6 => CGletter <= "101101"; -- -
--        when 7 => CGletter <= std_logic_vector("110000" + unsigned("000" & width)); -- Cursor Size (1 - 7)
--        when 8 => CGletter <= "100000"; -- " "
--        when 9 => CGletter <= "100000"; -- " "
--        when 10 => CGletter <= "100000"; -- " "
--        when 11 => CGletter <= "000011"; -- C
--        when 12 => CGletter <= "001111"; -- O
--        when 13 => CGletter <= "001100"; -- L
--        when 14 => CGletter <= "001111"; -- O
--        when 15 => CGletter <= "010010"; -- R
--        when 16 => CGletter <= "101101"; -- -
--        when 17 => CGletter <= "010111"; -- W
--        when 18 => CGletter <= "001111"; -- O
--        when 19 => CGletter <= "010010"; -- R
--        when 20 => CGletter <= "000100"; -- D
--        when 21 => CGletter <= "101101"; -- -
--        when 22 => CGletter <= typedASCII(53 downto 48); -- First character in typed "word"
--        when 23 => CGletter <= typedASCII(45 downto 40);
--        when 24 => CGletter <= typedASCII(37 downto 32);
--        when 25 => CGletter <= typedASCII(29 downto 24);
--        when 26 => CGletter <= typedASCII(21 downto 16);
--        when 27 => CGletter <= typedASCII(13 downto 8);
--        when 28 => CGletter <= typedASCII(5 downto 0); -- Last character in typed "word"
--        when others => CGletter <= "000000"; -- @
--    end case;
--end process;

--Sync and Counter Control Process
process (sysClk, reset)
begin
    if(reset = '1') then
        Hcounter <= 0;
        Vcounter <= 0;
    elsif(rising_edge(sysClk) and refreshPulse = '1') then
        if(HcounterNext = 0) then
            Vcounter <= VcounterNext;
        end if;
        Hcounter <= HcounterNext;
    end if;
end process;

VGA_HS  <=  '1' when Reset = '1' else
            '0' when Hcounter >= 660 and Hcounter <= 755 else
            '1';
VGA_VS  <=  '1' when Reset = '1' else
            '0' when Vcounter >= 494 and Vcounter <= 495 else
            '1';
HcounterNext    <=  Hcounter + 1 when Hcounter < 799 else
                    0;
VcounterNext    <=  Vcounter + 1 when Vcounter < 524 else
                    0;
                                     
process(sysClk, Reset)
begin
    if(Reset = '1') then
        currentSend <= "00000000";
        nextXaddr <= 0;
        state <= wait1;
    elsif (Reset = '0') then
        case state is
            when wait1 =>
                currentSend <= "00000000";
                if(Vcounter = 28 and size = '1') then
                    state <= sketchS2;
                elsif(Vcounter = 92) then
                    nextXaddr <= 0;
                    nextYaddr <= 0;
                    state <= sketchS1;
                end if;
                
            when sketchS1 =>
                if(Hcounter >= 192 and Hcounter <= 447 and Vcounter >= 92 and Vcounter <= 347) then
                    currentSend <= sketchOut;
                    if(Hcounter = 447) then
                        nextXaddr <= 0;
                    else
                        nextXaddr <= Hcounter - 191; -- address of next column
                    end if;
                elsif(Vcounter <= 347) then 
                    currentSend <= "00000000"; --black pixel
                    nextXaddr <= 0;
                    nextYaddr <= Vcounter - 92;
                else
                    state <= wait2;
                end if;
            
            when sketchS2 =>
                if(Hcounter >= 128 and Hcounter <= 511 and Vcounter >= 28 and Vcounter <= 411) then
                    currentSend <= sketchOut;
                    if(Hcounter = 511) then
                        nextXaddr <= 0;
                    else
                        nextXaddr <= ((Hcounter - 127) * 2) / 3;
                    end if;
                elsif(Vcounter <= 411) then
                    currentSend <= "00000000";
                    nextXaddr <= 0;
                    nextYaddr <= ((Vcounter - 28) * 2) / 3;
                else
                    state <= wait2;
                end if;
                          
            when wait2 =>
                currentSend <= "00000000";
                if(Vcounter = 440) then
                    state <= statusLine;
                end if;
                
            when statusLine =>
                whichLetter <= 0;
                endLetter <= 16;
                returnTo <= statusLine;
                currentSend <= "00000000";
                if(Vcounter <= 447 and Hcounter = 248) then
                    letterRow <= std_logic_vector(to_unsigned(Vcounter - 440,3));
                    nextCharPixel <= 7;
                    state <= printLetterRow;
                elsif(Vcounter > 447) then
                    state <= wordLine;
                end if;
                
            when printLetterRow =>
                --this if-statement controls whether the current pixel should be white or black
                if(CGout(nextCharPixel) = '1') then
                    currentSend <= "11111111"; -- white if current pixel should be on
                else
                    currentSend <= "00000000"; --black if current pixel should be off
                end if;
                --this if-statement gets the next pixel in the CGrom ready to be read
                if(nextCharPixel > 0) then
                    nextCharPixel <= nextCharPixel - 1;
                elsif(whichLetter < endLetter) then
                    nextCharPixel <= 7;
                    whichLetter <= whichLetter + 1;
                else
                    state <= returnTo;
                end if;
                
            when wordLine =>
                whichLetter <= 17;
                endLetter <= 28;
                returnTo <= wordLine;
                currentSend <= "00000000";
                if(Vcounter <= 455 and Hcounter = 284) then
                    letterRow <= std_logic_vector(to_unsigned(Vcounter - 448,3));
                    nextCharPixel <= 7;
                    state <= printLetterRow;
                elsif(Vcounter > 455) then 
                    state <= wait1;
                end if;
        end case;
    end if;
end process;
CGaddr <= CGletter & letterRow; --Creates CGrom address from current character and current row of pixels

sketchReadAddr  <= std_logic_vector(To_unsigned(nextXaddr,8)) & std_logic_vector(To_unsigned(nextYaddr,8));
    --Current Address of RAM to read
--Display controller for VGA.  The X and Y coordinates are derived from Hcounter
--and Vcounter   

VGA_out <= "00000000" when Hcounter > 639 or Vcounter > 479 else
            currentSend;
--Transformation of currentSend into the analog pinouts that actually go to the monitor
VGA_R <= VGA_out(7 downto 5) & currentSend(7); -- Red
VGA_G <= VGA_out(4 downto 2) & currentSend(4); -- Green
VGA_B <= VGA_out(1 downto 0) & currentSend(1 downto 0); -- Blue

end Behavioral;
