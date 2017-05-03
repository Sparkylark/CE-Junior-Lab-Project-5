library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Keyboard_Capture is
    Port (sysCLK    : in std_logic;
          kbCLK     : in std_logic;
          kbData    : in std_logic;
          pulse     : buffer std_logic;
          char      : out std_logic_vector(7 downto 0));
end Keyboard_Capture;

architecture Behavioral of Keyboard_Capture is

signal data : std_logic_vector(21 downto 0);
signal makeCodeTemp : std_logic_vector(7 downto 0);
signal makeCode : std_logic_vector(7 downto 0);
signal pulseInternal : std_logic;
signal charTemp :std_logic_vector(7 downto 0);
begin

makeCodeTemp <= data(9 downto 2); -- Scan code window
makeCode(7) <= makeCodeTemp(0);
makeCode(6) <= makeCodeTemp(1);
makeCode(5) <= makeCodeTemp(2);
makeCode(4) <= makeCodeTemp(3);
makeCode(3) <= makeCodeTemp(4);
makeCode(2) <= makeCodeTemp(5);
makeCode(1) <= makeCodeTemp(6);
makeCode(0) <= makeCodeTemp(7);

Process(kbCLK, kbData)
begin 
    if rising_edge(kbCLK) then
        data(21 downto 1) <= data(20 downto 0);
        data(0) <= kbData;
    end if;
end process;

Process(sysCLK)
begin
    if rising_edge(sysCLK) then
        if data(20 downto 13) = x"0F" then -- Break code window
            pulse <= '1'; -- pulseInternal <= '1';
            char <= charTemp;
        else 
            pulse <= '0'; -- pulseInternal <= '0';
        end if;
    end if;
end process;

charTemp <= x"41" when makeCode = x"1C" else --A        
            x"42" when makeCode = x"32" else --B        
            x"43" when makeCode = x"21" else --C        
            x"44" when makeCode = x"23" else --D        
            x"45" when makeCode = x"24" else --E        
            x"46" when makeCode = x"2B" else --F        
            x"47" when makeCode = x"34" else --G        
            x"48" when makeCode = x"33" else --H        
            x"49" when makeCode = x"43" else --I        
            x"4A" when makeCode = x"3B" else --J        
            x"4B" when makeCode = x"42" else --K        
            x"4C" when makeCode = x"4B" else --L        
            x"4D" when makeCode = x"3A" else --M        
            x"4E" when makeCode = x"31" else --N        
            x"4F" when makeCode = x"44" else --O        
            x"50" when makeCode = x"4D" else --P        
            x"51" when makeCode = x"15" else --Q        
            x"52" when makeCode = x"2D" else --R        
            x"53" when makeCode = x"1B" else --S        
            x"54" when makeCode = x"2C" else --T        
            x"55" when makeCode = x"3C" else --U        
            x"56" when makeCode = x"2A" else --V        
            x"57" when makeCode = x"1D" else --W        
            x"58" when makeCode = x"22" else --X        
            x"59" when makeCode = x"35" else --Y        
            x"5A" when makeCode = x"1A" else --Z        
            x"30" when makeCode = x"45" else --0        
            x"31" when makeCode = x"16" else --1        
            x"32" when makeCode = x"1E" else --2        
            x"33" when makeCode = x"26" else --3        
            x"34" when makeCode = x"25" else --4        
            x"35" when makeCode = x"2E" else --5        
            x"36" when makeCode = x"36" else --6        
            x"37" when makeCode = x"3D" else --7        
            x"38" when makeCode = x"3E" else --8        
            x"39" when makeCode = x"46" else --9        
            x"2F" when makeCode = x"5A" else --ENTER    
            x"5C" when makeCode = x"66" else --Backspace
            x"00";                           --Null

end Behavioral;
