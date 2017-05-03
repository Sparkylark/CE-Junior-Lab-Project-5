library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SketchRAM_Controller is
    Port ( 
        sysClk          :in std_logic;
        reset           :in std_logic;
        color           :in std_logic_vector(7 downto 0);
        width           :in std_logic_vector(2 downto 0);
        iX              :in std_logic_vector(7 downto 0);
        iY              :in std_logic_vector(7 downto 0);
        updateNow       :in std_logic;
        eraseNow        :in std_logic;
        busy            :out std_logic;
        wea             :out STD_LOGIC_VECTOR(0 DOWNTO 0);
        sketchWriteAddr :out STD_LOGIC_VECTOR(15 DOWNTO 0);
        sketchIn        :out STD_LOGIC_VECTOR(7 DOWNTO 0)  
    );
end SketchRAM_Controller;

architecture Behavioral of SketchRAM_Controller is

signal xCoord, yCoord           :unsigned(7 downto 0);
signal minX, maxX, minY, maxY   :unsigned(7 downto 0);
signal currentX, currentY       :unsigned(7 downto 0);
signal currentColor             :std_logic_vector(7 downto 0);
signal currentWidth             :unsigned(2 downto 0);
type machine is (ready, findTopLeft, findBotRight, updateSetup, eraseSetup,
                    writeEnable, writeDisable, writeNextFind);
signal state                    :machine:=ready;
signal writeColor               :std_logic_vector(7 downto 0); --color to be written to RAM

begin
process(sysClk, reset)
begin
if(reset = '1') then
    writeColor <= "11111111";
    busy <= '1';
    wea <= "0";
    state <= eraseSetup; --Clear the board when reset ends
elsif(rising_edge(sysClk)) then
    case state is
        when ready =>
            if(eraseNow = '1') then
                busy <= '1';
                state <= eraseSetup;
            elsif(updateNow = '1') then
                xCoord <= unsigned(iX);
                yCoord <= unsigned(iY);
                currentColor <= color;
                currentWidth <= unsigned(width);
                busy <= '1';
                state <= findTopLeft;
            else
                busy <= '0';
            end if;
            
        when findTopLeft => --Finds top left corner of update region
            if(currentWidth = 1 or currentWidth = 2) then
                minX <= xCoord;
                minY <= yCoord;
            elsif(currentWidth = 3 or currentWidth = 4) then
                if(xCoord - 1 >= 0) then
                    minX <= xCoord - 1;
                else minX <= to_unsigned(0,8);
                end if;
                if(yCoord - 1 >= 0) then
                    minY <= yCoord - 1;
                else minX <= to_unsigned(0,8);
                end if;
            elsif(currentWidth = 5 or currentWidth = 6) then
                if(xCoord - 2 >= 0) then
                    minX <= xCoord - 2;
                else minX <= to_unsigned(0,8);
                end if;
                if(yCoord - 2 >= 0) then
                    minY <= yCoord - 2;
                else minX <= to_unsigned(0,8);
                end if;
            elsif(currentWidth = 7) then
                if(xCoord - 3 >= 0) then
                    minX <= xCoord - 3;
                else minX <= to_unsigned(0,8);
                end if;
                if(yCoord - 3 >= 0) then
                    minY <= yCoord - 3;
                else minX <= to_unsigned(0,8);
                end if;
            end if;
            state <= findBotRight;
            
        when findBotRight => --Finds bottom right corner of update region
            if(currentWidth = 1) then
                maxX <= xCoord;
                maxY <= yCoord;
            elsif(currentWidth = 2 or currentWidth = 3) then
                if(xCoord + 1 <= 255) then
                    maxX <= xCoord + 1;
                else maxX <= to_unsigned(255,8);
                end if;
                if(yCoord + 1 <= 255) then
                    maxY <= yCoord + 1;
                else maxY <= to_unsigned(255,8);
                end if;
            elsif(currentWidth = 4 or currentWidth = 5) then
                if(xCoord + 2 <= 255) then
                    maxX <= xCoord + 2;
                else maxX <= to_unsigned(255,8);
                end if;
                if(yCoord + 2 <= 255) then
                    maxY <= yCoord + 2;
                else maxY <= to_unsigned(255,8);
                end if;
            elsif(currentWidth = 6 or currentWidth = 7) then
                if(xCoord + 3 <= 255) then
                    maxX <= xCoord + 3;
                else maxX <= to_unsigned(255,8);
                end if;
                if(yCoord + 3 <= 255) then
                    maxY <= yCoord + 3;
                else maxY <= to_unsigned(255,8);
                end if;
            end if;
            state <= updateSetup;
            
        when updateSetup => --Setup coordinates for updating the RAM
            currentX <= minX;
            currentY <= minY;
            writeColor <= currentColor;
            state <= writeEnable;
            
        when eraseSetup => --Setup for writing white pixels over the entire RAM
            minX <= to_unsigned(0,8);
            minY <= to_unsigned(0,8);
            maxX <= to_unsigned(255,8);
            maxY <= to_unsigned(255,8);
            currentX <= to_unsigned(0,8);
            currentY <= to_unsigned(0,8);
            writeColor <= "11111111";
            state <= writeEnable;
        
--Sub-state machine for iterating through all bounded pixels and updating their color       
        when writeEnable =>
            wea <= "1";
            state <= writeDisable;
            
        when writeDisable =>
            wea <= "0";
            state <= writeNextFind;
            
        when writeNextFind => --iterates through all pixels in the bounded square
            if(currentX < maxX) then
                currentX <= currentX + 1;
                state <= writeEnable;
            else
                currentX <= minX;
                if(currentY < maxY) then
                    currentY <= currentY + 1;
                    state <= writeEnable;
                else
                    state <= ready;
                end if;
            end if;
    end case;
end if;
end process;

sketchWriteAddr <= std_logic_vector(currentX) & std_logic_vector(currentY);
sketchIn <= writeColor;
end Behavioral;
