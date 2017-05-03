LIBRARY ieee;
   USE ieee.std_logic_1164.all;
	use IEEE.NUMERIC_STD.ALL;
	use IEEE.STD_LOGIC_ARITH;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;	

ENTITY vga_synchronizer IS
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
END vga_synchronizer;

ARCHITECTURE trans OF vga_synchronizer IS
   SIGNAL h_count          : STD_LOGIC_VECTOR(9 DOWNTO 0);
   SIGNAL v_count          : STD_LOGIC_VECTOR(9 DOWNTO 0);
   
   -- Declare intermediate signals for referenced outputs
   SIGNAL VGA_H_SYNC_xhdl0 : STD_LOGIC;
   SIGNAL VGA_V_SYNC_xhdl1 : STD_LOGIC;
	SIGNAL  video_h_on      : STD_LOGIC;
	SIGNAL  video_v_on      : STD_LOGIC;
	SIGNAL  video_on        : STD_LOGIC;
BEGIN

-- Horizontal sync

   -- Drive referenced outputs
   VGA_H_SYNC <= VGA_H_SYNC_xhdl0;
   VGA_V_SYNC <= VGA_V_SYNC_xhdl1;
   VGA_BLANK <= VGA_H_SYNC_xhdl0 AND VGA_V_SYNC_xhdl1;
   VGA_SYNC <= '0';
   px <= h_count;
   py <= v_count;

-- Generate Horizontal and Vertical Timing Signals for Video Signal
-- h_count counts pixels (640 + extra time for sync signals)
-- 
--  horiz_sync  ------------------------------------__________--------
--  h_count       0                640             660       755    799
--

   PROCESS (iCLK, iRST_N)
   BEGIN
      IF ((NOT(iRST_N)) = '1') THEN
         h_count <= "0000000000";
         VGA_H_SYNC_xhdl0 <= '0';
      ELSIF (iCLK'EVENT AND iCLK = '1') THEN
--         IF (h_count < to_stdlogicvector(H_SYNC_TOTAL - 1, 10)) THEN
         IF h_count < H_SYNC_TOTAL - 1 THEN			
            h_count <= h_count + "0000000001";
         ELSE
            h_count <= "0000000000";
         END IF;
--         IF (h_count >= to_stdlogicvector(H_SYNC_START, 10) AND h_count < to_stdlogicvector(H_SYNC_START + H_SYNC_WIDTH, 10)) THEN
         IF h_count >= H_SYNC_START AND h_count < H_SYNC_START + H_SYNC_WIDTH THEN
            VGA_H_SYNC_xhdl0 <= '0';
         ELSE
            VGA_H_SYNC_xhdl0 <= '1';
         END IF;
      END IF;
   END PROCESS;
	
--  
--  vertical_sync      -----------------------------------------------_______------------
--  v_count             0                                      480    494-495          524
--	
	
	   PROCESS (iCLK, iRST_N)
   BEGIN
      IF ((NOT(iRST_N)) = '1') THEN
         v_count <= "0000000000";
         VGA_V_SYNC_xhdl1 <= '0';
      ELSIF (iCLK'EVENT AND iCLK = '1') THEN
         IF h_count = H_START THEN
            IF v_count < V_SYNC_TOTAL - 1 THEN
               v_count <= v_count + "0000000001";
            ELSE
               
               v_count <= "0000000000";
            END IF;
            IF v_count >=  V_SYNC_START AND v_count < V_SYNC_START + V_SYNC_WIDTH THEN
               VGA_V_SYNC_xhdl1 <= '0';
            ELSE
               VGA_V_SYNC_xhdl1 <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;
	

   video_h_on <= '1' when h_count < H_PIXELS else '0';
   video_v_on <= '1' when v_count < V_PIXELS else '0';
   video_on <= video_h_on AND video_v_on;
   
   VGA_R <= iRed WHEN (video_on = '1') ELSE
            "0000";
   VGA_G <= iGreen WHEN (video_on = '1') ELSE
            "0000";
   VGA_B <= iBlue WHEN (video_on = '1') ELSE
            "0000";
	
END trans;
