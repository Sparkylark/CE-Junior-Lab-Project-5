library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity KB_toplevel is
      Port (color           : out std_logic_vector(7 downto 0);
            colorLongOut    :out std_logic_vector(23 downto 0);
            width           : out std_logic_vector(2 downto 0);
            size            : out std_logic;
            dataReady       : out std_logic;
            oBuffer         : out std_logic_vector(7 downto 0);
            typedString     : out std_logic_vector(55 downto 0);
            dataRecieved    : in std_logic;
            reset           : in std_logic;
            sysCLK          : in std_logic;
            kbCLK           : in std_logic;
            kbData          : in std_logic;
            charTL          : out std_logic_vector(7 downto 0));
end KB_toplevel;

architecture Behavioral of KB_toplevel is

component Keyboard_Capture is
    Port (sysCLK    : in std_logic;
          kbCLK     : in std_logic;
          kbData    : in std_logic;
          pulse     : out std_logic;
          char      : out std_logic_vector(7 downto 0));
end component;

component Keyboard_Decode is
    Port (CLK             : in std_logic;    
          pulse           : in std_logic;
          Data            : in std_logic_vector(7 downto 0);
          dataReceived    : in std_logic;
          reset           : in std_logic;
          size            : out std_logic;
          width           : out std_logic_vector(2 downto 0);
          color           : out std_logic_vector(7 downto 0);
          colorLongOut    :out std_logic_vector(23 downto 0);
          dataReady       : out std_logic;
          oBuffer         : out std_logic_vector(7 downto 0);
          typedString     : out std_logic_vector(55 downto 0));
end component;

Signal pulse        : std_logic;
signal char         : std_logic_vector(7 downto 0);

begin
charTL <= char;
inst_kb: Keyboard_Capture
    port map(   sysCLK  => sysCLK,
                kbCLK   => kbCLK,
                kbData  => kbData,
                pulse   => pulse,
                char    => char);
    
inst_decode: Keyboard_Decode
    port map(   CLK => sysCLK,
                pulse => pulse,
                Data => char,
                dataReceived => dataRecieved,
                reset => reset,
                size => size,
                width => width,
                color => color,
                colorLongOut => colorLongOut,
                dataReady => dataReady,
                oBuffer => oBuffer,
                typedString => typedString);

end Behavioral;
