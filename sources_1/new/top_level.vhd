library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
  Port ( 
    CLK100MHZ           :in std_logic;
    Btn_Reset           :in std_logic;
    Btn_Save            :in std_logic;
    PS2_CLK             :in std_logic;
    PS2_DATA            :in std_logic;
    RX                  :in std_logic;
    TX                  :out std_logic;
    SDA                 :inout std_logic;
    SCL                 :inout std_logic;
    VGA_R               :out std_logic_vector(3 downto 0);
    VGA_G               :out std_logic_vector(3 downto 0);
    VGA_B               :out std_logic_vector(3 downto 0);
    VGA_VS              :out std_logic;
    VGA_HS              :out std_logic;
    LED                 :out std_logic_vector(7 downto 0);
    JC                  :out std_logic_vector(3 downto 1);
    LCD_outTest         :out std_logic_vector(7 downto 0);
    LED16_R             :out std_logic;
    LED16_G             :out std_logic;
    LED16_B             :out std_logic
  );
end top_level;

architecture Behavioral of top_level is

component Reset_Delay IS	
    PORT (
        iCLK : IN std_logic;	
        oRESET : OUT std_logic
			);	
END component;

component btn_debounce_toggle is
GENERIC (
	CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF");  
	--CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"000F");  --Simulation ONLY
    Port ( BTN_I 	: in  STD_LOGIC;
           CLK 		: in  STD_LOGIC;
           BTN_O 	: out  STD_LOGIC;
           TOGGLE_O : out  STD_LOGIC);
end component;

component clk_enabler is
	GENERIC (
		CONSTANT cnt_max : integer := 49999999); -- 1 second
	port(	
		clock:		in std_logic;
		Reset:      in std_logic; 
		clk_en: 	out std_logic
	);
end component;

component KB_toplevel is
      Port (color           : out std_logic_vector(7 downto 0);
            colorLongOut    : out std_logic_vector(23 downto 0);
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
end component;

component SketchRAM_Controller is
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
end component;

component SketchRAM IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

component CGROM IS
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

component UART_Transmit is
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
end component;

component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;

component I2C_ULogic_Coordinates is
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
end component;

--component VGA_Controller is
--    Port ( 
--        sysClk          :in std_logic;
--        reset           :in std_logic;
--        refreshPulse    :in std_logic;
--        color           :in std_logic_vector(7 downto 0);
--        width           :in std_logic_vector(2 downto 0);
--        size            :in std_logic;
--        typedASCII      :in std_logic_vector(55 downto 0);
--        sketchReadAddr  :out std_logic_vector(15 downto 0);
--        sketchOut       :in std_logic_vector(7 downto 0);
--        CGaddr          :out std_logic_vector(8 downto 0);
--        CGout           :in std_logic_vector(7 downto 0);
--        VGA_R           :out std_logic_vector(3 downto 0);
--        VGA_G           :out std_logic_vector(3 downto 0);
--        VGA_B           :out std_logic_vector(3 downto 0);
--        VGA_VS          :out std_logic;
--        VGA_HS          :out std_logic 
--    );
--end component;

component VGA_Controller_v2 is
    Port ( 
        sysClk          :in std_logic;
        reset           :in std_logic;
        pX              :in std_logic_vector(9 downto 0);
        pY              :in std_logic_vector(9 downto 0);
        color           :in std_logic_vector(7 downto 0);
        width           :in std_logic_vector(2 downto 0);
        size            :in std_logic;
        typedASCII      :in std_logic_vector(55 downto 0);
        sketchReadAddr  :out std_logic_vector(15 downto 0);
        sketchOut       :in std_logic_vector(7 downto 0);
        CGaddr          :out std_logic_vector(8 downto 0);
        CGout           :in std_logic_vector(7 downto 0);
        oRed            :out std_logic_vector(3 downto 0);
        oGreen          :out std_logic_vector(3 downto 0);
        oBlue           :out std_logic_vector(3 downto 0)
    );
end component;

component vga_synchronizer IS
   GENERIC (
      
      H_SYNC_TOTAL  : INTEGER := 800;
      H_PIXELS      : INTEGER := 640;
      H_SYNC_START  : INTEGER := 659;
      H_SYNC_WIDTH  : INTEGER := 96;
      V_SYNC_TOTAL  : INTEGER := 525;
      V_PIXELS      : INTEGER := 480;
      V_SYNC_START  : INTEGER := 493;
      V_SYNC_WIDTH  : INTEGER := 2;
      H_START       : INTEGER := 699
   );
   PORT (
      iCLK          : IN STD_LOGIC;
      iRST_N        : IN STD_LOGIC;
      iRed          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      iGreen        : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      iBlue         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      px            : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
      py            : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
      VGA_R         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      VGA_G         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      VGA_B         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      VGA_H_SYNC    : OUT STD_LOGIC;
      VGA_V_SYNC    : OUT STD_LOGIC;
      VGA_SYNC      : OUT STD_LOGIC;
      VGA_BLANK     : OUT STD_LOGIC
   );
END component;

component lcd_Wrapper is
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
end component;

component triColorLED is
	port(	CLK			: in std_logic;
			redIn		: in std_logic_vector(7 downto 0);
			greenIn 	: in std_logic_vector(7 downto 0);
			blueIn		: in std_logic_vector(7 downto 0);
			redOut		: out std_logic;
			greenOut	: out std_logic;
			blueOut		: out std_logic);
end component;

signal initReset, resetDeb, saveDeb :std_logic;
signal Reset, Reset_n               :std_logic;
signal baudClkEn                    :std_logic;
signal dataReady, dataReceived, RAMbusy, updateNow, eraseNow    :std_logic;
signal keyboardBuf, iX, iY          :std_logic_vector(7 downto 0);
signal wea                          :std_logic_vector(0 downto 0);
signal sketchWriteAddr, sketchReadAddr  :std_logic_vector(15 downto 0);
signal sketchIn, sketchOut          :std_logic_vector(7 downto 0);
signal charAddr                     :std_logic_vector(8 downto 0);
signal CGrow                        :std_logic_vector(7 downto 0);
signal refreshPulse                 :std_logic;
signal color                        :std_logic_vector(7 downto 0);
signal width                        :std_logic_vector(2 downto 0);
signal size                         :std_logic;
signal ICena, rw, ICbusy, ack_error :std_logic;
signal ICreset_n                    :std_logic;
signal ICaddr                       :std_logic_vector(6 downto 0);
signal ICdata_wr, ICdata_rd         :std_logic_vector(7 downto 0);
signal typedASCII                   :std_logic_vector(55 downto 0);
signal pX, pY                       :std_logic_vector(9 downto 0);
signal Red, Grn, Blu                :std_logic_vector(3 downto 0);
signal colorLong                    :std_logic_vector(23 downto 0);

signal CLK25MHZ                     :std_logic:='0';
signal clkCount                     :std_logic:='0';


begin
Reset <= initReset or resetDeb;
Reset_n <= not Reset;

--25 MHz clock divider for VGA synchronizer
process(CLK100MHZ)
begin
    if(rising_Edge(CLK100MHZ)) then
        if(clkCount = '0') then
            clkCount <= '1';
        else
            clkCount <= '0';
            CLK25MHZ <= not CLK25MHZ;
        end if;
    end if;
end process;

init_reset_Delay: reset_Delay
port map (iCLK => CLK100MHZ, oRESET => initReset);

init_reset_Debounce: btn_debounce_toggle
GENERIC map(CNTR_MAX => X"FFFF")
	--CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"000F");  --Simulation ONLY
Port map( 	BTN_I => Btn_Reset,	
				CLK => CLK100MHZ,
				BTN_O => resetDeb,
				TOGGLE_O => open);
				
init_save_Debounce: btn_debounce_toggle
GENERIC map(CNTR_MAX => X"FFFF")
    --CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"000F");  --Simulation ONLY
Port map(     BTN_I => Btn_Save,    
                CLK => CLK100MHZ,
                BTN_O => saveDeb,
                TOGGLE_O => open);

init_115_2KHz_Enabler: clk_enabler
Generic map(cnt_max => 868)
Port map(   clock => CLK100MHZ,
            Reset => Reset,
            clk_en => baudClkEn);
            
init_25MHz_Enabler: clk_enabler
Generic map(cnt_max => 4)
Port map(   clock => CLK100MHZ,
            Reset => Reset,
            clk_en => refreshPulse);

init_KBtop: KB_toplevel
Port map(   color => color,            
            colorLongOut => colorLong,    
            width => width,
            size => size,
            dataReady => dataReady,
            oBuffer => keyboardBuf,
            typedString => typedASCII,
            dataRecieved => dataReceived,
            reset => Reset,
            sysCLK => CLK100MHZ,
            kbCLK => PS2_CLK,
            kbData => PS2_DATA,
            charTL => LED(7 downto 0)
            );

init_UART_Transmit: UART_Transmit 
Port map(
        sysClk => CLK100MHZ,       
        baudClkEn => baudClkEn,    
        reset => Reset,
        save => saveDeb,        
        dataReady => dataReady,
        keyboardBuf => keyboardBuf,
        typedASCII => typedASCII,
        dataReceived => dataReceived,
        iX => iX,
        iY => iY,    
        RAMbusy => RAMbusy,   
        updateNow => updateNow,
        eraseNow => eraseNow,
        RX => RX,
        TX => TX
    );

Sketch_CTRL: SketchRAM_Controller
    Port map( 
        sysClk => CLK100MHZ,
        reset => Reset,
        color => color,
        width => width,
        iX => iX,
        iY => iY,
        updateNow => updateNow,
        eraseNow => eraseNow,
        busy => RAMbusy,
        wea => wea,
        sketchWriteAddr => sketchWriteAddr,
        sketchIn => sketchIn
    );

init_i2c_master: i2c_master
  GENERIC MAP(
    input_clk => 100_000_000, --input clock speed from user logic in Hz
    bus_clk   => 100_000)   --speed the i2c bus (scl) will run at in Hz
  PORT MAP(
    clk => CLK100MHZ,
    reset_n => ICreset_n,
    ena => ICena,
    addr => ICaddr,
    rw => rw,
    data_wr => ICdata_wr,
    busy => ICbusy,
    data_rd => ICdata_rd,
    ack_error => ack_error,
    sda => SDA,
    scl => SCL
    );

init_i2c_ULogic: I2C_ULogic_Coordinates
Port map( 	
		iClk => CLK100MHZ,
		iReset => Reset,
		oReset_n => ICreset_n,
		ena	=> ICena,
		addr => ICaddr,
		rw => rw,
		data_rd => ICdata_rd,
		data_wr	=> ICdata_wr,
		ack_error => ack_error,
		busy => ICbusy,
		X => iX,
		Y => iY
		);

init_VGA_CTRL_V2: VGA_Controller_v2
    Port map( 
        sysClk => CLK25MHZ,
        reset => Reset,
        pX => pX,
        pY => pY,
        color => color,
        width => width,
        size => size,
        typedASCII => typedASCII,
        sketchReadAddr => sketchReadAddr,
        sketchOut => sketchOut,
        CGaddr => charAddr,
        CGout => CGrow,
        oRed => Red,
        oGreen => Grn,
        oBlue => Blu
    );

init_synchronizer: vga_synchronizer
   GENERIC MAP(
      
      H_SYNC_TOTAL => 800,
      H_PIXELS => 640,
      H_SYNC_START => 659,
      H_SYNC_WIDTH => 96,
      V_SYNC_TOTAL => 525,
      V_PIXELS => 480,
      V_SYNC_START => 493,
      V_SYNC_WIDTH => 2,
      H_START => 699
   )
   PORT MAP(
      iCLK => CLK25MHZ,
      iRST_N => Reset_n,
      iRed => Red,
      iGreen => Grn,
      iBlue => Blu,
      px => pX,
      py => pY,
      VGA_R => VGA_R,
      VGA_G => VGA_G,
      VGA_B => VGA_B,
      VGA_H_SYNC => VGA_HS,
      VGA_V_SYNC => VGA_VS,
      VGA_SYNC => open,
      VGA_BLANK => open
   );


init_sketchRAM: SketchRAM
PORT map (
    clka => CLK100MHZ,
    wea => wea,
    addra => sketchWriteAddr,
    dina => sketchIn,
    clkb => CLK100MHZ,
    addrb => sketchReadAddr,
    doutb => sketchOut
  );

init_CGROM: CGROM
PORT MAP (
    clka => CLK100MHZ,
    addra => charAddr,
    douta => CGrow
  );
  
inst_LCD_Control: lcd_Wrapper
PORT map(
    CLK			=> CLK100MHZ,
    reset		=> Reset,
    colorLong	=> colorLong,
    width_in	=> width,
    size		=> size,
    typedString	=> typedASCII,
    e			=> JC(3),
    rs			=> JC(1),
    rw			=> JC(2),
    data_out    => LCD_outTest
    );  

inst_TriColor: triColorLED
port map(
    CLK         => CLK25MHZ,
    redIn       => colorLong(23 downto 16),
    greenIn       => colorLong(15 downto 8),
    blueIn       => colorLong(7 downto 0),
    redOut       => LED16_R,
    greenOut       => LED16_G,
    blueOut       => LED16_B); 

end Behavioral;
